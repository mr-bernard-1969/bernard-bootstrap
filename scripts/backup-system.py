#!/usr/bin/env python3
"""
Workspace backup system with rotation.
Usage: python3 backup-system.py [--dest local|b2|s3] [--keep-daily 7] [--keep-weekly 4]
"""
import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path.home() / '.openclaw' / 'workspace'
BACKUP_DIR = Path.home() / '.openclaw' / 'backups'
STATE_FILE = BACKUP_DIR / 'backup-state.json'


def load_state():
    """Load backup state tracking."""
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {'daily': [], 'weekly': []}


def save_state(state):
    """Save backup state tracking."""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)


def create_tarball(dest_path):
    """Create compressed tarball of workspace."""
    print(f"📦 Creating tarball: {dest_path}")
    cmd = [
        'tar', 'czf', str(dest_path),
        '-C', str(WORKSPACE.parent),
        'workspace',
        '--exclude=node_modules',
        '--exclude=.git',
        '--exclude=__pycache__',
        '--exclude=*.pyc'
    ]
    subprocess.run(cmd, check=True)
    size_mb = dest_path.stat().st_size / 1024 / 1024
    print(f"✅ Created {size_mb:.1f} MB tarball")
    return dest_path


def upload_b2(local_path):
    """Upload to Backblaze B2."""
    bucket = os.getenv('B2_BACKUP_BUCKET')
    if not bucket:
        print("❌ B2_BACKUP_BUCKET not set")
        sys.exit(1)
    
    remote_name = f"openclaw-workspace/{local_path.name}"
    print(f"☁️  Uploading to B2: {remote_name}")
    cmd = ['b2', 'upload-file', bucket, str(local_path), remote_name]
    subprocess.run(cmd, check=True)
    print(f"✅ Uploaded to B2")


def upload_s3(local_path):
    """Upload to AWS S3."""
    bucket = os.getenv('S3_BACKUP_BUCKET')
    if not bucket:
        print("❌ S3_BACKUP_BUCKET not set")
        sys.exit(1)
    
    remote_name = f"openclaw-workspace/{local_path.name}"
    print(f"☁️  Uploading to S3: s3://{bucket}/{remote_name}")
    cmd = ['aws', 's3', 'cp', str(local_path), f"s3://{bucket}/{remote_name}"]
    subprocess.run(cmd, check=True)
    print(f"✅ Uploaded to S3")


def rotate_backups(state, keep_daily, keep_weekly):
    """Remove old backups beyond retention limits."""
    now = datetime.datetime.now()
    
    # Remove old daily backups
    while len(state['daily']) > keep_daily:
        old = state['daily'].pop(0)
        old_path = Path(old['path'])
        if old_path.exists():
            old_path.unlink()
            print(f"🗑️  Removed old daily: {old_path.name}")
    
    # Remove old weekly backups
    while len(state['weekly']) > keep_weekly:
        old = state['weekly'].pop(0)
        old_path = Path(old['path'])
        if old_path.exists():
            old_path.unlink()
            print(f"🗑️  Removed old weekly: {old_path.name}")
    
    return state


def main():
    parser = argparse.ArgumentParser(description='Backup workspace with rotation')
    parser.add_argument('--dest', choices=['local', 'b2', 's3'], default='local',
                        help='Backup destination (default: local)')
    parser.add_argument('--keep-daily', type=int, default=7,
                        help='Number of daily backups to keep (default: 7)')
    parser.add_argument('--keep-weekly', type=int, default=4,
                        help='Number of weekly backups to keep (default: 4)')
    args = parser.parse_args()
    
    if not WORKSPACE.exists():
        print(f"❌ Workspace not found: {WORKSPACE}")
        sys.exit(1)
    
    # Create backup directory
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    
    # Load state
    state = load_state()
    
    # Determine backup type (daily or weekly)
    now = datetime.datetime.now()
    is_weekly = now.weekday() == 6  # Sunday
    backup_type = 'weekly' if is_weekly else 'daily'
    
    # Create tarball
    timestamp = now.strftime('%Y%m%d-%H%M%S')
    filename = f"workspace-{backup_type}-{timestamp}.tar.gz"
    local_path = BACKUP_DIR / filename
    
    create_tarball(local_path)
    
    # Upload if requested
    if args.dest == 'b2':
        upload_b2(local_path)
    elif args.dest == 's3':
        upload_s3(local_path)
    
    # Update state
    backup_record = {
        'path': str(local_path),
        'timestamp': now.isoformat(),
        'type': backup_type
    }
    state[backup_type].append(backup_record)
    
    # Rotate old backups
    state = rotate_backups(state, args.keep_daily, args.keep_weekly)
    
    # Save state
    save_state(state)
    
    print(f"✅ Backup complete: {filename}")
    print(f"📊 Daily: {len(state['daily'])}/{args.keep_daily}, Weekly: {len(state['weekly'])}/{args.keep_weekly}")


if __name__ == '__main__':
    main()
