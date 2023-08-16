# Gitlab repository: https://gitlab.com/ped0071/gke-ingress-nginx

# Gitlab Runner

```
A pipeline foi feita com o Gitlab CI/CD, e por isso foi feita a criação de uma instância manual na GCP e adicionado algumas configurações para que rode a pipeline diretamente nesta instância. Foi instalado na máquina o Terraform, Ansible, Gitlab Runner e Docker, foi feito também a criação de uma chave ssh do tipo rsa para fazer conexão com a máquina que vai ser criada com comunicação com o Cluster.
```

# Terraform

```
Na pasta network foi criada a parte da criação da VPC e expondo algumas variáveis que serão preenchidas no arquivo de criação do cluster puxando como module.

No arquivo k8s.tf é feita a criação do module "network" com o source da pasta network criada anteriormente, e preenchendo as variáveis necessárias:
- ``vpc_name``
- ``subnet_name``
- ``region``
- ``subnet_cidr``

Também nele é criado 2 networks peering para a comunicação entre a rede default e a rede que foi criado anteriormente, isso é necessário para que a instância do runner tenha permissão para se conectar a instância que realizará o deploy das configurações no cluster.
Foi definido a criação do cluster como privado tão como os nodes e desativando o default node pool para a criação personalizada da instância node, com os pools de IPs configuradas e somente liberado o IP da VPC privada, a instância criada é uma e2-medium no modelo spot.
No arquivo nat.tf é configurado o router para a VPC privada, e também utilizando o module do cloud-nat configurado o nat com o router criado.
No arquivo vm.tf é alocado um ip do tipo interno na VPC privada para ser associado a instância que irá aplicar as configurações no kubernetes, uma instância do tipo e2-medium com sistema operacional Debian e conectada a nossa VPC Privada criada anteriormente, também é passado um metadata para arquivar a SSH-Key criada na máquina runner para fazer a conexão via ssh entre as instâncias que é disponibilizada através da variável atribuída tanto no terraform quanto no gitlab.

Nas regras de firewall existem 3 configurações, o "allow-ssh" que permite tráfego na porta 22 para o ip da GCP onde é possível conectar via console GCP, o "allow-internal-network" para que libere todo tipo de tráfego vindo do range de IP da nossa VPC Privada, e o "allow-network-default" que libera todo tipo de tráfego vindo do range de IP da VPC Default da GCP, para que seja possível a conexão entre esta instância e a instância do Gitlab Runner.

No arquivo variables.tf foi definido algumas variáveis simples como por exemplo:
- ``region``
- ``project``
- ``location``
- ``cluster_name``
- ``ssh_key_file - que está configurada como vazia pois será preenchida com a variável do Gitlab.``
```

# Ansible

```
Nos arquivos de configuração do Ansible existem 4 roles configuradas.

O Gcloud, que é onde será feita a configuração de autenticação ao user criado, e a instalação do pacote "google-cloud-sdk-gke-gcloud-auth-plugin" para ser feita a conexão com o cluster do GKE, e também atrelado a algumas variáveis:
- ``gke_cluster_name``
- ``gcp_zone``
- ``gcp_project_id``

A role kube_install é onde será feita toda a instalação do kubectl, para que seja possível estarmos gerenciando via linha de comando todas as configurações.

A role Helm é onde será feita a instalação do helm e feita a instalação do nginx-ingress via helm já com seus repositórios configurados, feito também a instalação do pacote "jq" que será utilizado mais a frente para expor uma variável dentro da máquina, é feito a cópia do arquivo de configuração do kubernetes que se chama "hello-world.yml" para dentro da instância e após isso temos um pause de 60 segundos para que o service do nginx-ingress vincule um External IP ao svc.

E por último o deploy_kubernetes que executa um comando que irá filtrar especificamente o External IP do service Nginx-ingress e mandá-lo para o arquivo ip.json que será localizado em /home/gcp/ip.json. Logo após executando um "sed -i" para que substitua a variável "$NGINX_INGRESS_IP" dentro do nosso arquivo de configuração do kubernetes localizado em /tmp/hello-world.yml e substituindo pelo conteúdo armazenado dentro do ip.json. Em seguida ele executa um delete em um "validatingwebhookconfiguration" do nginx-ingress que faz termos um erro na hora da execução do deploy, e logo após executamos o "kubectl apply -f /tmp/hello-world.yml" que irá aplicar as configurações feitas no arquivo.

Temos também o arquivo hosts que é onde está configurado o IP da máquina em que ele irá se conectar o usuário a ser utilizado, junto com o arquivo "playbook.yml" que seta a ordem de execução das roles.
```

# Gitlab CI/CD

```
No arquivo de pipeline é declarado 3 stages:
- ``deploy``
- ``config``
- ``build``
É declarado que a variável "$credentials_file" que está armazenado dentro do repositório do Gitlab, na primeira configuração temos o "docker build" que será onde irá realizar o build da imagem e subir para o dockerhub.
Na próxima configuração temos o "provisioning_infrastructure" onde é realizado o comando "echo "$credentials_file" > credentials.json", que irá armazenar a informação da configuração do usuário no arquivo credentials.json que é necessário para executarmos os comandos do terraform. Logo em seguida temos a execução dos comandos "terraform init" que instala todas as dependências necessárias para ser executado os arquivos e o "terraform apply -auto-approve" para que aplique as configurações de terraform. E isso somente será executado na branch "main" com a tag "runner" que é a máquina que está configurada com o Gitlab Runner.

Na última configuração temos o "Deploy Kubernetes", onde irá e ser executado o comando "ansible-playbook" setando que a private key utilizada será a localizada em /home/gitlab-runner/id_rsa, setando o arquivo hosts que é o ip da nossa instância que irá realizar as configurações do kubernetes, e passando o env "ANSIBLE_HOST_KEY_CHECKING=False" para não termos que confirmar o host key, e executável somente na branch "main" e com tag "runner".

Foi declarado também algumas variáveis dentro do Gitlab:

- ``TF_VAR_ssh_key_file - Que expõe a chave ssh.pub na variável do terraform``
- ``credentials_file - Que é o nosso arquivo de login do usuário da GCP``
- ``CI_REGISTRY_USER - Que é o meu login no DockerHub``
- ``CI_REGISTRY_PASSWORD - Que é a minha senha no DockerHub``
```

# Aplicação Nodejs

```
Também adicionei uma aplicação simples em NodeJS que printa um "Hello-World", "Version: 0.1" e o "Hostname:", e junto disso o Dockerfile para criar a imagem no DockerHub.
```

# Execução do projeto

```
Para ser executado o projeto fora da pipeline é preciso passar a variável ssh_key_file, manualmente dentro do variables.tf que seria você criar uma chave ssh do tipo rsa, e passar na variável o usuário que será feito para logar na instância e a chave logo em seguida user:chave.

É preciso também ter o arquivo de credenciais do usuário gcp na sua máquina como "credentials.json", e também fazer as alterações necessárias do arquivo variables.tf como por exemplo setar o projeto em que irá executar, e logo após executar o comando "terraform init" e "terraform apply".

Na parte do ansible, temos que ter criado uma máquina configurada com o ansible e também com o arquivo ssh dentro dela, para que possa ser feito a comunicação entre as máquinas, verificar as variáveis dentro da role gcloud e alterá-las e executar o comando "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key=/home/gitlab-runner/.ssh/id_rsa -i hosts playbook.yml".

No final da execução do comando ansible, ele retornará um “conteúdo.ip.stdout:” e na frente um ip, é só copiar este ip e inserir na frente “.nip.io” que você será redirecionado a URL da aplicação rodando.
```
