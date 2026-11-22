import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> pickPlatformImageBytes() async {
  if (!Platform.isWindows) return null;

  try {
    // Open native Windows file picker for PNG/JPG clothing photos
    const script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dlg = New-Object System.Windows.Forms.OpenFileDialog
\$dlg.Filter = "Image Files (*.png;*.jpg;*.jpeg)|*.png;*.jpg;*.jpeg"
\$dlg.Title = "Select a clothing photo"
if (\$dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dlg.FileName
}
''';
    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-STA', '-Command', script],
    );
    final selectedPath = (result.stdout as String).trim();
    if (selectedPath.isNotEmpty) {
      final file = File(selectedPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
  } catch (_) {
    // Fall back to preset snapshot if dialog is unavailable (e.g. headless test)
  }
  return null;
}
