#!/bin/bash

currentMili=''
comm=''
factors=''
tests=''
variableList=()
variableNames=()
testList=()

resolveFile() {
    # pega o nome do arquivo
    fileName=$1
    # busca o comando a ser executado
    comm=$(sed -n "/^COMANDO:/ {n;p}" $fileName)
    # pega o milisegundo atual para ser o nome da copia
    currentMili=$(date +%s%N)
    # troca o caractere problematico por um mais suave e faz uma copia do arquivo
    tr '*' '&' < $fileName > $currentMili
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

# prepara os fatores
prepareVariables() {
    for variables in ${factors[@]}
    do
        local replace=''
        local name=${variables//=*/$replace}
        variableNames+=($name)
        variables=$(echo $variables | sed 's/[()]//g')
        local preparedValue=${variables//*=/$replace}
        IFS=','
        local temp
        read -a temp <<< $preparedValue
        local tList=()
        for i in ${temp[@]}
        do
            local c  
            IFS=' '
            read -a c <<< $i
            tList+=($c)
        done
        tList+=("END")
        variableList+=(${tList[@]})
    done
}

# prepara os ensaios
prepareTests() {
    local tempTest=$(echo $tests | tr '\n' ' ')
    for test in ${tempTest[@]}
    do
        local repl=''
        test=$(echo $test | sed 's/[()]//g')
        local prepValue=${test//*=/$repl}
        local tp
        read -a tp <<< $prepValue
        local tpList=()
        for j in ${tp[@]}
        do
            local newT=$(echo $j | tr ',' ' ' )
            tpList+=($newT)
        done
        tpList+=("END")
        testList+=(${tpList[@]})
    done
}

main() {
    # pega o nome do arquivo de configuração
    configFile=$1
    # passa para o método de tratamento
    resolveFile $configFile
    prepareVariables
    prepareTests
    local counter=0
    local localComm=$comm
    local commands=()
    for test in ${testList[@]}
    do
        # verifica se não chegou em um ponto de fim da lista, fim da lista da lista
        if [[ $test != "END" ]] 
        then
            # se encontrou o &, quer dizer que precisa variar os valores
            if [[ $test == "&" ]] 
            then
                local value=()
                local endCounter=0 
                # então vai na lista de valores de variaveis
                for g in ${variableList[@]}
                do  
                    # pega os valores daquela variavel
                    if [[ $g != "END" ]]
                    then
                        value+=($g)
                    else
                        if [[ $endCounter == $counter ]]
                        then
                            break
                        else
                            endCounter=$(($endCounter+1))
                            value=()
                        fi
                    fi
                done
                # depois de encontrar os values de variação, precisa criar comandos
                # para a quantidade de variação
                for v in ${value[@]}
                do
                    # pega como base o que ta salvo no localComm
                    commands+=(${localComm//${variableNames[$counter]}/$v})
                done
            else
                # encontrou um valor fixo, então so precisa dar um replace em seu valor no comando
                # se não tiver comandos, então so substitui o comando local
                if [[ ${#commands[@]} == 0 ]]
                then
                    localComm=${localComm//${variableNames[$counter]}/$test}
                    #echo " -- $localComm -- "
                    commands+=($localComm)
                else
                    # se tiver, passa na lista de comandos, substituindo
                    # for (( x=0 ; ((x-${#commands}-1)) ; x=(($x+1)) ))
                    # do
                        
                    #     ${commands[$x]}=${commands[$x]//${variableNames[$counter]}/$test}
                    # done
                    local l=()
                    for c in ${commands[@]}
                    do
                        l+=(${c//${variableNames[$counter]}/$test})
                    done
                    commands=()
                    commands=${l[@]}
                fi
            fi
        else
            echo ${commands[@]}
            # reseta o comando novamente
            localComm=$comm
            commands=()
            # reseta o counter
            counter=$((-1))
        fi
        counter=$(($counter+1))
    done
    #echo ${variableList[@]}
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