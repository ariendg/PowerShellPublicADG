$diploma = Read-Host "Voor welk diploma wil jij gaan? (Kleine diploma (K) / Grote diploma (G))"

switch ($diploma.ToUpper()) {
    "K" { Write-Output "Je hebt gekozen voor het Kleine diploma." }
    "G" { Write-Output "Je hebt gekozen voor het Grote diploma." }
    default { Write-Output "Ongeldige keuze. Kies 'K' voor Kleine diploma of 'G' voor Grote diploma." }
}
if ($diploma.ToUpper() -eq "K") {
    Write-Output "Kleine diploma ="
    Write-Output "Tafels: 1,2,3,4,5 & 10"
    Write-Output "30 Vragen"
}
if ($diploma.ToUpper() -eq "G") {
    Write-Output "Grote diploma ="
    Write-Output "Tafels: 1 - 10"
    Write-Output "40 Vragen"
}
function Get-RandomSom {
    param (
        [int]$maxTafel
    )
    $rand = Get-Random -Minimum 1 -Maximum ($maxTafel + 1)
    $rand2 = Get-Random -Minimum 1 -Maximum ($maxTafel + 1)
    return "$rand x $rand2 ="
}

function Check-Antwoord {
    param (
        [string]$som,
        [int]$antwoord
    )
    $parts = $som -split ' x | ='
    $correct = [int]$parts[0] * [int]$parts[1]
    return $correct -eq $antwoord
}

$maxTafel = if ($diploma.ToUpper() -eq "K") { 5 } else { 10 }
$score = 0

for ($i = 1; $i -le 30; $i++) {
    $som = Get-RandomSom -maxTafel $maxTafel
    $antwoord = [int](Read-Host "Wat is de uitkomst van $som")

    $parts = $som -split ' x | ='
    $correctAnswer = [int]$parts[0] * [int]$parts[1]

    if (Check-Antwoord -som $som -antwoord $antwoord) {
        Write-Output "Correct!"
        $score++
    } else {
        Write-Output "Incorrect. Het juiste antwoord is $correctAnswer"
    }
}

Write-Output "Je score is $score van de 30."