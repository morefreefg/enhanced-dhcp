#!/usr/bin/env python3
"""
Fixed IPK Generator for OpenWrt
Creates IPK packages with correct UID/GID for OpenWrt compatibility
"""

import os
import struct
import time
import sys

def create_ar_header(filename, size, uid=0, gid=0, mode=0o100644):
    """Create properly formatted AR archive header with root ownership"""
    timestamp = int(time.time())
    
    # AR file header format (60 bytes total):
    # filename (16) + timestamp (12) + uid (6) + gid (6) + mode (8) + size (10) + magic (2)
    header = struct.pack(
        '16s12s6s6s8s10s2s',
        filename.encode('ascii').ljust(16, b' '),
        str(timestamp).encode('ascii').ljust(12, b' '),
        str(uid).encode('ascii').ljust(6, b' '),
        str(gid).encode('ascii').ljust(6, b' '),
        oct(mode)[2:].encode('ascii').ljust(8, b' '),
        str(size).encode('ascii').ljust(10, b' '),
        b'`\n'
    )
    return header

def create_fixed_ipk(build_dir, output_file):
    """Create IPK with proper OpenWrt-compatible format"""
    
    # Required files
    debian_binary = os.path.join(build_dir, 'debian-binary')
    control_tar = os.path.join(build_dir, 'control.tar.gz')
    data_tar = os.path.join(build_dir, 'data.tar.gz')
    
    # Check if all files exist
    for f in [debian_binary, control_tar, data_tar]:
        if not os.path.exists(f):
            print(f"Error: Missing file {f}")
            return False
    
    print(f"🔧 Creating fixed IPK: {output_file}")
    
    with open(output_file, 'wb') as ipk:
        # Write AR archive signature
        ipk.write(b'!<arch>\n')
        
        # Add each file with proper root ownership
        for filename in ['debian-binary', 'control.tar.gz', 'data.tar.gz']:
            filepath = os.path.join(build_dir, filename)
            file_size = os.path.getsize(filepath)
            
            # Write AR header with UID=0, GID=0 (root)
            header = create_ar_header(filename, file_size)
            ipk.write(header)
            
            # Write file content
            with open(filepath, 'rb') as f:
                ipk.write(f.read())
            
            # Pad to even boundary if needed
            if file_size % 2 == 1:
                ipk.write(b'\n')
            
            print(f"  ✅ Added {filename} (size: {file_size}, owner: root:root)")
    
    print(f"✅ IPK created successfully: {output_file}")
    return True

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 create_fixed_ipk.py <build_dir> <output_ipk>")
        sys.exit(1)
    
    build_dir = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(build_dir):
        print(f"Error: Build directory {build_dir} does not exist")
        sys.exit(1)
    
    success = create_fixed_ipk(build_dir, output_file)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()