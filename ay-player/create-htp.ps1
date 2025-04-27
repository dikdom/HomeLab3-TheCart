
# $binaryData = [Byte[]] (0x01, 0x02, 0x03, 0x04)

# [IO.File]::WriteAllBytes(".\test.bin", $binaryData)

.\compile.bat

$binaryHead = Get-Content -Path ".\header.bin" -Encoding Byte -Raw
$fileInfo = Get-Item ".\player.bin"
$fileSizeBytes = $fileInfo.Length
$binaryFileSize = [Byte[]] ([Byte]($fileSizeBytes%256), [Byte][Math]::Floor($fileSizeBytes / 256) )
$b1binaryContent = Get-Content -Path ".\player.bin" -Encoding Byte -Raw
$chkSum = ($b1binaryContent | Measure-Object -sum).sum
$binaryTail = [Byte[]] ([Byte] ($chkSum % 256), 75)
$b2binaryContent = Get-Content -Path ".\block2.bin" -Encoding Byte -Raw
$fullContent = $binaryHead + $binaryFileSize + $b1binaryContent + $binaryTail + $b2binaryContent
# $fullContent = $binaryHead + $binaryFileSize + $b1binaryContent + $binaryTail

[IO.File]::WriteAllBytes("c:\Users\vasss\RetroMachines\HomeLab\ay-player\player.htp", $fullContent)