import os
import glob

test_dir = '/Users/sean/Desktop/blue/rc_configurator_flutter/test'
dart_files = glob.glob(os.path.join(test_dir, '**', '*.dart'), recursive=True)

moved_files = [
    'link/link_transport.dart',
    'link/memory_link_transport.dart',
    'link/mock_protocol_link_transport.dart',
    'protocol/bluetooth_frame.dart',
    'protocol/bluetooth_protocol_types.dart',
    'protocol/bluetooth_protocol_codec.dart',
    'protocol/bluetooth_frame_parser.dart',
    'protocol/bluetooth_protocol_client.dart',
    'protocol/bluetooth_crc8.dart',
    'logging/bluetooth_log_store.dart'
]

for filepath in dart_files:
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    needs_ble = False
    modified = False
    
    for line in lines:
        is_moved = False
        for moved in moved_files:
            if f"package:rc_configurator_flutter/src/lib/{moved}" in line:
                is_moved = True
                needs_ble = True
                modified = True
                break
        
        if not is_moved:
            new_lines.append(line)
            
    if needs_ble:
        # insert it after the last import
        last_import = 0
        for i, line in enumerate(new_lines):
            if line.startswith('import '):
                last_import = i
        
        # Check if already imported
        already = any("package:rc_ble/rc_ble.dart" in l for l in new_lines)
        if not already:
            new_lines.insert(last_import + 1, "import 'package:rc_ble/rc_ble.dart';\n")
            
    if modified:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        print(f"Fixed {filepath}")

