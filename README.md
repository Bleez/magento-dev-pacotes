# Magento para desenvolvimento de pacotes Bleez

Este repositório contém uma instalação limpa do Magento com comandos úteis para desenvolvimento de pacotes Bleez.

## Iniciando

Esse repositório foi pensado para trabalhar em conjunto com o [Ambiente para desenvolvimento de pacotes Magento 2](https://github.com/Bleez/docker-dev-magento). Isso significa que o próprio ambiente já instalará o Magento para você.

Caso você queira trabalhar sem usar o ambiente você precisará instalar as dependências rodando `composer install` e posteriormente instalando o Magento por conta própria.

## Registrando os pacotes

Se você instalou o Magento a partide do Ambiente de Desenvolvimento na raiz do mesmo terá uma pasta chamada `/packages`. Nela você colocará todos os pacotes que pretende trabalhar.

A lógica para trabalhar com os pacotes é simples:

Você colocará o código em uma pasta onde você possa editar os arquivos e depois vai "enganar" o Magento fazendo-o achar que esse pacote está na nuvem quando na verdade ele está na sua máquina.

No fim das contas o Magento vai instalar o seu pacote na pasta `/vendor` com um link simbólico para a pasta onde tem os arquivos que você vai editar.

Os passos a seguir ensinam como fazer isso.

### Trabalhando em pacotes já existentes

Entre na pasta `/packages` e faça clone do projeto que você quer trabalhar. Por exemplo, se você quer trabalhar com o Bleez Correios você irá executar os comandos:

```bash
$ cd packages

$ git clone git@github.com:Bleez/module-correios-adapter.git
```

Com você terá nesse diretório os arquivos do modulo onde poderá editar e commitar normalmente.

O próximo passo é "enganar" o Magento.

Para isso edite o arquivo `composer.json` **na raiz do Magento** e procure pela seção `repositories` (por volta da linha 68).

Originalmente ela é assim:

```json
    ...
    "repositories": [
        {
            "type": "composer",
            "url": "https://repo.magento.com/"
        }
    ],
    ...
```

Coloque adicione essa linha:

```json
{ "type": "path", "url": "./packages/diretorio-do-pacote", "options": { "symlink": true }}
```

Usando o exemplo do Bleez Correios, a seção `repositories` vai ficar assim:

```json
    ...
    "repositories": [
        {
            "type": "composer",
            "url": "https://repo.magento.com/"
        },
        { "type": "path", "url": "./packages/module-correios-adapter", "options": { "symlink": true }}
    ],
    ...
```

> Não esqueça do ponto-e-vírgula depois da declaração do repositório do Magento

Depois procure a seção `require` e informe ao composer para instalar seu pacote. Ela ficará assim:

```json
    ...
    
    "require": {
        "bleez/module-correios-adapter": "*",
        "magento/product-community-edition": "2.3.4"
    },

    ...
```

Depois disso basta rodar `composer update` que o seu pacote será instalado no Magento apontando para o diretório dentro de `/packages`.

> Se você estiver usando o Ambiente de Desenvolvimento rode com `composer update` de dentro do container.

### Trabalhando com novos pacotes

O processo é bem parecido com o processo anterior. A diferença é que no lugar de clonar um repositório já existente você irá criar um diretório dentro de `/packages` e fazer o mesmo processo para "enganar" o Magento.

Não se esqueça de depois iniciar o git dentro do diretório do seu pacote e commitar seu trabalho.

### Dependências de outros módulos Bleez

O exemplo do Bleez Correios anterior não é completamente correto pois ele depende do Bleez Shippings - `bleez/module-shippings` - para funcionar.

Você pode comprovar isso olhando o `composer.json` do próprio módulo em `/packages/module-correios-adapter/composer.json`, na seção `require`.

```json
    ...

    "require": {
        "php": "^7.1.0",
        "magento/product-community-edition": "^2.3",
        "brunoviana/php-correios": "1.0.x-dev",
        "bleez/module-shippings": "~1.0"
    },

    ...
```

> Se você estiver criando seu pacote do zero que dependa de qualquer outro pacote, sempre coloque ele no require com a versão correta que você está trabalhando. Assim evitará problemas de compatibilidade no futuro.

Isso significa que quando você rodar o `composer update` ele irá falhar pois ele não consegue encontrar o Bleez Shippings. Uma mensagem parecida com essa irá aparecer:

```bash
$ composer update 

Your requirements could not be resolved to an installable set of packages.

  Problem 1
    - Installation request for bleez/module-correios-adapter * -> satisfiable by bleez/module-correios-adapter[1.0.0].
    - bleez/module-correios-adapter 1.0.0 requires bleez/module-shippings ~1.0 -> no matching package found.
 ```

 Para resolver isso você precisa informar na seção `repositories` do `composer.json` **da raiz do Magento** onde ele deve buscar pelo Bleez Shippings.


 Para isso você irá informar o link do repositório do Github, logo seu `composer.json` ficará assim:

 ```json
    ...

    "repositories": [
        {
            "type": "composer",
            "url": "https://repo.magento.com/"
        },
        { "type": "path", "url": "./packages/module-correios-adapter", "options": { "symlink": true }},
        { "type": "vcs", "url":  "git@github.com:Bleez/module-shippings.git" }
    ],

    ...
```

## Desenvolvendo pacotes

Para desenvolver pacotes, seja criando novos, seja atualizando já existentes, é importante saber algumas padronizações e alguns comandos para isso.

A seguir vou explicar tudo que é preciso saber para desenvolver pacotes no padrão Bleez.

### Estrutura de código

A estrutura de código que utilizamos não é 100% em cima de como o Magento trabalha. Se você observar a estrutura dos pacotes do Magento você verá que todo o código fica na raíz do pacote.

Achamos que a melhor forma de organizar é como está documentado em [Standard PHP Package Skeleton](https://github.com/php-pds/skeleton) que é uma documentação que tenta padronizar como a maioria dos pacotes escritos em PHP se organizam.

Se pegarmos como exemplo o Bleez Shippings teremos essa organização:

```bash
$ tree
.
|-- composer.json
|-- registration.php
|-- src
|   |-- Interfaces
|   |   `-- Model
|   |       `-- Carrier
|   |           `-- AdapterInterface.php
|   |-- Model
|   |   |-- Carrier
|   |   |   `-- Configuracao.php
|   |   |-- Carrier.php
|   |   `-- DescobridorDeAdapters.php
|   |-- Setup
|   |   |-- InstallData.php
|   |   |-- SetupData.php
|   |   `-- Uninstall.php
|   `-- etc
|       |-- adminhtml
|       |   `-- system.xml
|       |-- config.xml
|       `-- module.xml
`-- tests
    `-- Unit
        |-- Carrier
        |   `-- ConfiguracaoTest.php
        |-- CarrierTest.php
        |-- DescobridorDeAdaptersTest.php
        `-- Setup
            `-- SetupDataTest.php

13 directories, 16 files
```

Olhando a raiz do pacote teremos:

| Arquivo ou diretório               | O que é |
| ---------------------------------- | ------------------------------------------------------------------- |
| `composer.json`                    | Definições gerais do pacote                                         |
| `registration.php`                 | Registra o pacote como um módulo/tema/widget/tradução no Magento    |
| `/src`                             | Arquivos do pacote usando a organização padrão do Magento           |
| `/tests`                           | Arquivos com os testes do pacote                                    |

Para essa estrutura funcionar não tem segredo, basta especificar os caminhos do namespace dentro do `composer.json` na seção `autoload` e o caminho dos arquivos do módulo dentro de `registration.php`.

```json
    // composer.json

    ...

    "autoload": {
        "files": [
            "registration.php"
        ],
        "psr-4": {
            "Bleez\\Correios\\": "src/",
            "Bleez\\Correios\\Test\\": "tests/"
        }
    },

    ...
```
```php
<?php

// registration.php

\Magento\Framework\Component\ComponentRegistrar::register(
    \Magento\Framework\Component\ComponentRegistrar::MODULE,
    'Bleez_Correios',

    __DIR__ . '/src' // <--- define a pasta /src aqui
);
```
