#Script Automação - Versão 1.4
#1.1 - Descrição do script: Script de limpeza de disco C, incluindo diretórios temporários de profile dos usuários.
#1.2 - Adicionada funcionalidade para apagar profiles com mais de 3 dias sem uso de servidores TS, corrigida função de TOP profiles para rodar com usuário de maquina; adicionado cabeçalho padrão na versão 1.4.
#1.3 - Adicionado comando para deletar dumps do splunk. Removida função de TOP15 maiores profiles, que demorava muito tempo para rodar em servidores TS.
#1.3 - Alterada variavel $env:HOMEDRIVE usada na limpeza dos diretorios para $env:SystemDrive devido aos jump servers usarem o D: como homedrive

#Cabecalho Padrao CSD - Versao 1.4.1

#Capturar nome do script
#Na solicitação de serviços pedir para carregar a variavel "$scriptname" com o nome do script.ps1
#Para teste da execução local do script Se a variavel não existir ela vai pegar o nome no script que está sendo executado

if (!$scriptname) {$scriptname = $MyInvocation.MyCommand.Name}

#Criar variavel de Data e Hora
$UDate = {Get-Date -format "yyyy.MM.dd-HHmmss"}

#Criar arquivo de log no formato [C:\MONITORACAO\AUTOMACAO\LOGS\[nome do script].log]
$testelogfile =  Test-Path C:\MONITORACAO\AUTOMACAO\LOGS 
if (!$testelogfile) {New-Item C:\MONITORACAO\AUTOMACAO\LOGS\ -ItemType Directory}
$autlog = "C:\MONITORACAO\AUTOMACAO\LOGS\$scriptname.log"
$autlog1 = "C:\MONITORACAO\AUTOMACAO\LOGS\$scriptname.log1"

#Iniciando LOG
"Inicio da execução do script $scriptname" | out-file -Append $autlog
$($UDate.Invoke())+"`n" | out-file -Append $autlog
$filelogsize = Get-ChildItem $autlog
$filemaxsize = [int64]30mb
if((($filelogsize).length) -ige $filemaxsize) {
    get-content $autlog | out-file $autlog1
    "Restartfile" | out-file $autlog
    $($UDate.Invoke()) | out-file -Append $autlog
}

#Criar variavel do status da execução do script - usado pela monitoracao para saber se o script funcionou
$LASTEXITCODE = 1

#Criar a pasta para o arquivo de lock
$testelogfile =  Test-Path C:\MONITORACAO\AUTOMACAO\LOCK 
if (!$testelogfile) {New-Item C:\MONITORACAO\AUTOMACAO\LOCK\ -ItemType directory}

#Criar a variavel para criar o arquivo de lock para todas as automações
$autlock = "C:\MONITORACAO\AUTOMACAO\LOCK\automacao.lock"

#Criar a variavel para criar o arquivo de lock para uma única automação
$autlockone = "C:\MONITORACAO\AUTOMACAO\LOCK\$scriptname.lock"

#Criar script para ativar o lock na pasta
$autlocklog = "C:\MONITORACAO\AUTOMACAO\LOCK\lock_automacao.log"
$scriptonofflock = "C:\MONITORACAO\AUTOMACAO\LOCK\ativa-desativa_automacao.ps1"
$testelockscript = Test-Path $scriptonofflock 
if (!$testelockscript) {
    new-item $scriptonofflock -ItemType File
    "if (Test-Path $autlock) {" | out-file -Append $scriptonofflock
    "Read-host Tecle [ENTER] para reativar a automação" | out-file -Append $scriptonofflock
    "Remove-Item $autlock" | out-file -Append $scriptonofflock
    '"**********************************************"' + " | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    "get-date | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    '"Usuário = $env:USERNAME"' + " | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    '"Monitoração reativada"' + " | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    '"**********************************************"' + " | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    "}" | out-file -Append $scriptonofflock
    "else" | out-file -Append $scriptonofflock
    "{" | out-file -Append $scriptonofflock
    "Read-host Tecle [ENTER] para paralizar -LOCK- na automação" | out-file -Append $scriptonofflock
    "new-item $autlock -ItemType File" | out-file -Append $scriptonofflock
    "get-date | out-file -Append $autlock" | out-file -Append $scriptonofflock
    '"Usuário = $env:USERNAME"' + " | out-file -Append $autlock" | out-file -Append $scriptonofflock
    '"**********************************************"' + " | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    "get-date | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    '"Usuário = $env:USERNAME"' + " | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    '"Monitoração colocada em LOCK"' + " | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    '"**********************************************"' + " | out-file -Append $autlocklog" | out-file -Append $scriptonofflock
    "}" | out-file -Append $scriptonofflock
}

#Funcao que analisa LASTEXITCODE, retorna resultado para ferramenta de automacao e finaliza a log.
# Para cada codigo de erro, alterar a mensagem que será passada no log do incidente, por exemplo: 
#    Write-Host "<RESUMO DO QUE O SCRIPT FEZ> Return Code: $LASTEXITCODE ($statusfinal)"
# Caso necessario, novos EXITCODEs podem ser adicionados com as respectivas mensagens.
# comando para chamar a funcao: FinalizaLog $LASTEXITCODE

function FinalizaLog($LASTEXITCODE){
    Switch($LASTEXITCODE)
    {
        0 {
            $MensagemLog = "Script de limpeza executado com sucesso"
            $statusfinal = "SUCESSO"
            Write-Host "$MensagemLog. Return Code: $LASTEXITCODE ($statusfinal)"
            }
        1 {
            $MensagemLog = "Script de limpeza não foi efetivo"
            $statusfinal = "FALHA"
            Write-Host "$MensagemLog. Return Code: $LASTEXITCODE ($statusfinal)"
            }
        2 {
            $MensagemLog = "Automacao está em LOCK para o script $scriptname"
            $statusfinal = "LOCK"
            Write-Host "$MensagemLog. Return Code: $LASTEXITCODE ($statusfinal)"
            }
        3 {
            $MensagemLog = "Automacao está em LOCK para todos os scripts"
            $statusfinal = "LOCK"
            Write-Host "$MensagemLog. Return Code: $LASTEXITCODE ($statusfinal)"
            }
        4 {
            $MensagemLog = "Script de limpeza executado com sucesso, porém não foi liberado espaço. Favor verificar"
            $statusfinal = "FALHA"
            Write-Host "$MensagemLog. Return Code: $LASTEXITCODE ($statusfinal)"
            }
    }
    #Final da LOG
    $MensagemLog+"`n" | out-file -Append $autlog
    $($UDate.Invoke()) | out-file -Append $autlog
    "Fim da execução do script $scriptname" | out-file -Append $autlog
    "*******************************************************" | out-file -Append $autlog
}

#Verifica se está em LOCK todas as automações. Caso positivo muda o exit code para 3 e finaliza o script
$testelock =  Test-Path $autlock 
if ($testelock) {
    $LASTEXITCODE = 3

    #registra resultado do script
    FinalizaLog $LASTEXITCODE
    exit
}

#Verifica se está em LOCK uma automação. Caso positivo muda o exit code para 2 finaliza o script
$testelockone =  Test-Path $autlockone
if ($testelockone) {
    $LASTEXITCODE = 2

    #registra resultado do script
    FinalizaLog $LASTEXITCODE
    exit
}

#Inicio do script
#****************************************************

# DECLARAÇÃO DE VARIAVEIS

# IMPORTA MODULO POWERSHELL
Import-Module servermanager


# APAGA OS PERFMONS MAIS ANTIGOS DO QUE 5 DIAS DOS DIRETORIOS C:\Reskitsup\PerfLog_SSID E C:\PerfLogs
TamanhoDir("$env:SystemDrive\Reskitsup\PerfLog_SSID") | Out-File $autlog -Append
Get-ChildItem $env:SystemDrive\Reskitsup\PerfLog_SSID -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -le (Get-Date).AddDays(-5)} | Remove-Item -Recurse
Get-ChildItem $env:SystemDrive\PerfLogs -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -le (Get-Date).AddDays(-5)} | Remove-Item -Recurse

# APAGA OS ARQUIVOS DE DEBUG DIAG QUE ESTEJAM A MAIS DE 5 DIAS NO SERVIDOR
if(Test-Path "$env:SystemDrive\Program Files\DebugDiag\Logs"){
    Get-ChildItem -Path "$env:SystemDrive\Program Files\DebugDiag\Logs" -Include *.* -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -le (Get-Date).AddDays(-5)} | ForEach-Object { $_.Delete()}
}
if(Test-Path "$env:SystemDrive\Program Files (x86)\DebugDiag\Logs"){
    Get-ChildItem -Path "$env:SystemDrive\Program Files\DebugDiag\Logs" -Include *.* -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -le (Get-Date).AddDays(-5)} | ForEach-Object { $_.Delete()}
}

"Limpando os diretorios...."

# CRIA UM EVENTO 9999 EM SYSTEM
New-EventLog –LogName System –Source “ScriptAutomacao” -ErrorAction SilentlyContinue

#****************************************************

#Final da LOG
FinalizaLog $LASTEXITCODE