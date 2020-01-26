# delete-files

*1.1 - Descrição do script: Script de limpeza de disco C, incluindo diretórios temporários de profile dos usuários.

1.2 - Adicionada funcionalidade para apagar profiles com mais de 3 dias sem uso de servidores TS, corrigida função de TOP profiles para rodar com usuário de maquina; adicionado cabeçalho padrão na versão 1.4.

1.3 - Adicionado comando para deletar dumps do splunk. Removida função de TOP15 maiores profiles, que demorava muito tempo para rodar em servidores TS.

1.3 - Alterada variavel $env:HOMEDRIVE usada na limpeza dos diretorios para $env:SystemDrive devido aos jump servers usarem o D: como homedrive
