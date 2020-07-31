node {
    try {
        def remote = [:]
        remote.name = 'master-node'
        remote.host = "172.27.11.81"
        remote.user = 'root'
        withCredentials([string(credentialsId: 'kubernetes-master-password', variable: 'KubePassword')]) {
            remote.password = "${KubePassword}"
        }
        remote.allowAnyHosts = true
        def gitRepoURL = 'http://192.168.75.53/root/k8s-kubespray-deploy.git'
        def MYACR = 'ecsdemoRegistry'
        def MYAKS = 'devCluster'
        def MYRCG = 'ecsondemo'

        stage("Git Clone") {
            git credentialsId: '7cf7dbf3-4fa5-4983-8ce6-f9f7369f3094', url: "${gitRepoURL}"
            commitId = sh(returnStdout: true, script: 'git rev-parse HEAD')
            echo "${commitId}"
        }
        
        if (!pushCloudRepo.toBoolean()) {
        
        stage("Cleanup existing cluster"){
         sshagent(['kube-53']) {
          sh """
           #chmod 777 init.sh
           #./init.sh 'Ecssupport09' ${masterNode} ${node1} ${node2} ${node3}
           # cp -rfp inventory/hosts.yaml inventory/mycluster/hosts.yaml
           cp -rfp inventory/sample.yaml inventory/mycluster/hosts.yaml 
           cat yes | ansible-playbook -i inventory/mycluster/hosts.yaml reset.yml
           ansible-playbook -i inventory/mycluster/hosts.yaml uninstall.yaml
          """
          }
        }
        
        stage("initial setup") {
          sh """
             chmod 777 init.sh
             #./init.sh 'Ecssupport09' ${masterNode} ${node1} ${node2} ${node3}
             #cp -rfp inventory/hosts.yaml inventory/mycluster/hosts.yaml
             #cp -rfp inventory/sample.yaml inventory/mycluster/hosts.yaml 
             ansible-playbook -i inventory/mycluster/hosts.yaml setup.yaml
            """ 
        }
        
        stage("Deploying kubernetes cluster"){
           build '/3.Database'
           sh "cat yes | ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml"
        }
      
        stage("additional-installation"){
          sh "ansible-playbook -i inventory/mycluster/hosts.yaml additional-installation.yaml"
          //ansiblePlaybook(credentialsId: 'PA172', inventory: 'hosts', playbook: 'additional-installation.yaml')
        }
        
        } else {
        //for Azure Cloud
        //edit azure configfiles ./azure-config 
         stage("initial setup") {
          sh """
            #sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            #sudo sh -c 'echo -e "[azure-cli]
            #name=Azure CLI
            #baseurl=https://packages.microsoft.com/yumrepos/azure-cli
            #enabled=1
            #gpgcheck=1
            #gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
            #sudo yum install azure-cli
             az login -u accounts@ecsfin.com -p 3Cssupport2019
             cp -rfp inventory/sample inventory/azcluster
             cp -rfp azure_config/all contrib/azurerm/group_vars/
             cp -rpf azure_config/*.yml inventory/azcluster/group_vars/all/
          """
        }
        
        stage("deploying kubernetes") {
         sh """
          #cd contrib/azurerm
          az aks create -g ${MYRCG} -n ${MYAKS}  --node-count 2 --vm-set-type VirtualMachineScaleSets  --load-balancer-sku standard \
           --enable-cluster-autoscaler  --min-count 1  --max-count 3
          az aks get-credentials -n ${MYAKS} -g ${MYRCG} --overwrite-existing
          az acr create -n ${MYACR} -g ${MYRCG} --sku basic --admin-enabled true
          az aks update -n ${MYAKS} -g ${MYRCG} --attach-acr ${MYACR}
          #az acr credential show -n $MYACR  
          az acr login -n $MYACR
         """
         build '/3.Database'
        //sh "variable="az acr credential show -n $MYACR""
       //  sh "echo $($variable | jq '.passwords[0].value')   | sed -e 's/^"//' -e 's/"$//' | docker login ecsdemoregistry.azurecr.io -u ecsdemoRegistry --password-stdin"
        }
        stage("Persistant volume setup"){
         sh """
         chmod 777 /root/database/azure/installfile_share.sh
         /root/database/azure/installfile_share.sh ecsstorageaccount ecsondemo westus aksshare
         """
        }
        stage("addon installation"){
         sh """
         chmod 777 inventory/azureaddon.sh
         inventory/azureaddon.sh
         """
        }
        } 
        stage("Service Deployment"){
          build '/discovery-service-latest'
          build '/config-service-latest'
          sleep(50)
          build '/traditional-message-service-latest'
          build '/message-service-latest'
          build '/transform-service-latest'
          build '/payment-service-latest'
          build '/RPP-connector-service-latest'
          build '/payment-response-service-latest'
          build '/kong-gateway-config'
          build '/scheduler-metrics'
          build '/dashboard-ui'
        }
        
    }catch(err){   
            echo err.getMessage()
            mail bcc: '', body: '''Hi All
            Please check Jenkins as the following error has occured in Project config-Server
            ERROR :- '''+err.getMessage(), cc: '', from: '', replyTo: '', subject: 'Jenkins ERROR in Initial-Setup', to: 'skmidhun09@gmail.com'
            error('Pipline Stage Failed')
        }
 }