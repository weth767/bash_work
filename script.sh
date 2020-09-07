#!/bin/bash

currentMili=''
comm=''
factors=''
tests=''
variableList=()
testList=()

resolveFile() {
    # pega o nome do arquivo
    fileName=$1
    # busca o comando a ser executado
    comm=$(sed -n "/^COMANDO:/ {n;p}" $fileName)
    # pega o milisegundo atual para ser o nome da copia
    currentMili=$(date +%s%N)
    # copia o arquivo
    $(cp -u -f $fileName $currentMili)
    # adiciona a palava fim ao final do arquivo
    sed -i -e '$aFIM' $currentMili
    # remove espaços em branco
    sed -i "s/ //g" $currentMili
    # remove linhas em branco
    sed -i '/^\s*$/d' $currentMili
    # remove linhas de comentario
    sed -i '/^#/d' $currentMili
    # pega os fatores
    factors=$(sed -n '/FATORES:/,/COMANDO:/{/FATORES:/!{/COMANDO:/!p}}' $currentMili)
    # pega o ensaio
    tests=$(sed -n '/ENSAIOS:/,/FIM/{/ENSAIOS:/!{/FIM/!p}}' $currentMili)
}

prepareValue() {
    value=$1
    replace=''
    preparedValue=${value//*=/$replace}
    testList+=($preparedValue)
}

prepareVariables() {
    # prepara os fatores
    for variables in $factors
    do
        variableList+=($variables)
    done
    # prepara os ensaios
    list=()
    for test in $tests
    do
        list+=($test)
    done
    for test in ${list[@]}
    do
        prepareValue $test
    done
}

main() {
    # pega o nome do arquivo de configuração
    configFile=$1
    # passa para o método de tratamento
    resolveFile $configFile
    prepareVariables
    #$echo $comm
    #echo $factors
    $(rm -rf $currentMili)
}

main $1

# sed -n '/^COMANDO:/ {n;p}' config.txt
# transforma tudo em lower case: sed -e 's/\(.*\)/\L\1/'
# remove espaços em branco: sed -i "s/ //g" config.txt
# adiciona a palavra FIM ao fim do arquivo: sed -i -e '$aFIM' config.txt
# remove linhas em branco: sed -i '/^\s*$/d' config.txt 
# remove linhas que começam com #: sed -i '/^#/d' config.txt
# sed -n '/FATORES:/,/COMANDO:/{/FATORES:/!{/COMANDO:/!p}}' config.txt
# sed -n '/ENSAIO:/,/FIM:/{/FATORES:/!{/COMANDO:/!p}}' config.txt