# Magento para desenvolvimento de pacotes Bleez

Este repositório contém uma instalação limpa do Magento com comandos úteis para desenvolvimento de pacotes Bleez.

## Iniciando

Esse repositório foi pensado para trabalhar em conjunto com o [Ambiente para desenvolvimento de pacotes Magento 2](https://github.com/Bleez/docker-dev-magento). Isso significa que o próprio ambiente já instalará o Magento para você.

Caso você queira trabalhar sem usar o ambiente você precisará instalar as dependências rodando `composer install` e posteriormente instalando o Magento por conta própria.

## Registrando os pacotes

Se você instalou o Magento a partir do Ambiente de Desenvolvimento na raiz do mesmo terá uma pasta chamada `/packages`. Nela você colocará todos os pacotes que pretende trabalhar.

A lógica para trabalhar com os pacotes é simples:

Você colocará o código em uma pasta onde você possa editar os arquivos e depois vai "enganar" o Magento fazendo-o achar que esse pacote está na nuvem quando na verdade ele está na sua máquina.

No fim das contas o Magento vai instalar o seu pacote na pasta `/vendor` com um link simbólico para a pasta onde tem os arquivos que você vai editar.

Os passos a seguir ensinam como fazer isso.

#### :eyes: Observação sobre a pasta `/packages` 

A pasta `/packages` não tem nenhuma relação com o Magento, isso significa que qualquer código que estiver la dentro será automaticamente lido pelo Magento.

O motivo dessa pasta existir é simplesmente para que fique padronizado um local onde ficará todos os arquivos que você estiver editando e commitando para o Github. Assim os scripts de teste e de análise de padrão de código (vou explicar mais a frente) irão rodar somente lá dentro e não no Magento inteiro.

Isso significa que para que o Magento reconheça o seu código como um pacote instalável é necessário recorrer aos passos seguintes para "enganar" o Magento e fazê-lo pensar que seu código é um pacote pronto para instalação.

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

> :warning: Se você estiver usando o Ambiente de Desenvolvimento rode com `composer update` de dentro do container.

### Trabalhando com novos pacotes

O processo é bem parecido com o processo anterior. A diferença é que no lugar de clonar um repositório já existente você irá criar um diretório dentro de `/packages` e fazer o mesmo processo para "enganar" o Magento.

Não se esqueça de depois iniciar o git dentro do diretório do seu pacote e commitar seu trabalho.

> :warning: **Importante**:
> É fortemente indicado você usar o [modelo de pacote que criamos](https://github.com/Bleez/modelo-pacote) para já iniciar o seu pacote com boa parte das configurações necessárias prontas.

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

> :warning: Se você estiver criando seu pacote do zero que dependa de qualquer outro pacote, sempre coloque ele no require com a versão correta que você está trabalhando. Assim evitará problemas de compatibilidade no futuro.

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
## Testando pacotes

Para testar os pacotes basta você rodar o comando `composer test-unit`.

Este comando irá automaticamente buscar por testes unitários dentro da pasta `/packages`.

Exemplo
```bash
$ composer test-unit
```

Dependendo da quantidade de pacotes que você possui, você pode sentir a necessidade de rodar apenas um pacote específico para testar mais rápido. Para isso você deve rodar `composer test-unit -- /packages/meu-pacote`.

Exemplo
```bash
$ composer test-unit -- /packages/module-shippings
```

Caso você queira rodar apenas os testes de uma classe ou método específico você pode usar a opção `--filter`.

Por exemplo, se um dos meus métodos de teste se chama `test_Deve_Cadastrar_Usuario_Com_Sucesso()` eu posso executar:

```bash
$ composer test-unit -- --filter Deve_Cadastrar_Usuario_Com_Sucesso
```
Também é possível rodar os testes em um diretório especifico e aplicar o filtro.

Exemplo
```bash
$ composer test-unit -- /packages/module-shippings --filter Deve_Cadastrar_Usuario_Com_Sucesso
```

### Relatório de cobertura de código

Se você tiver o Xdebug instalado e habilitado será criado automaticamente dentro de `/var/www/test-reports` um relatório de cobertura de código.

Use esse relatório para saber se você está cobrindo bem seu código com testes. O ideal é ter o código com no mínimo 90% de cobertura de código. Se você conseguir isso o relatório ficará todo verdinho. :)

Se você estiver usando o Ambiente de Desenvolvimento o Xdebug já vem instalado e configurado, porém por motivos de performance ele não vem habilitado por padrão.

Isso significa que você pode rodar seus testes sem gerar relatório inicialmente, porém quando desejar que os relatórios sejam gerados execute o comando `xdebug` para habilitá-lo e em seguida rode os testes.

```bash
$ xdebug

========= XDebug was enabled =========

$ composer test-unit

> ./vendor/bin/phpunit -c dev/tests/unit/phpunit.xml.packages --verbose --colors=always
PHPUnit 6.5.14 by Sebastian Bergmann and contributors.

Runtime:       PHP 7.2.31 with Xdebug 2.9.5
Configuration: /var/www/dev/tests/unit/phpunit.xml.packages

............................                                      28 / 28 (100%)

Time: 8.41 seconds, Memory: 20.00MB

OK (28 tests, 62 assertions)

Generating code coverage report in HTML format ... done
```

> :warning: Evite lentidão no desenvolvimento dos seus pacotes desabilitando o Xdebug se você não estiver usando. Para isso execute novamente `xdebug` no terminal que ele ficará desabilitado. Assim os testes não gerarão relatórios sempre que você rodá-os.

## Padronização de código

Esse repositório também possui comandos para checagem de padronização de código e pra conserto de padrão de código.

Manter o padrão de código é importante para facilitar a leitura de quem for trabalhar no pacote depois de você.

Todos os pacotes Bleez criados serão incluidos em uma ferramenta de CI que irá validar se o padrão de código está ok e caso contrário você não será capaz de dar merge das suas modificações na `master`.

Para ajudar nisso alguns scripts foram criados para ajudar nesse processo.

### Análise de padrão PSR-2

A PSR-2 é uma padronizaçao internacional de desenvolvimento PHP que dá algumas diretrizes de como o código deve ser escrito.

Rodando o comando `composer check-psr2` você terá um relatório com qualquer código que não se adeque a PSR-2 dentro da pasta `/packages`.

Exemplo

```bash
$ composer check-psr2

> phpcs -p --standard=PSR2 packages/*/src
.......E. 9 / 9 (100%)



FILE: ...ww/packages/module-shippings/src/Model/DescobridorDeAdapters.php
----------------------------------------------------------------------
FOUND 1 ERROR AND 1 WARNING AFFECTING 2 LINES
----------------------------------------------------------------------
 13 | WARNING | [ ] Line exceeds 120 characters; contains 210
    |         |     characters
 14 | ERROR   | [x] Opening brace should be on a new line
----------------------------------------------------------------------
PHPCBF CAN FIX THE 1 MARKED SNIFF VIOLATIONS AUTOMATICALLY
----------------------------------------------------------------------

Time: 2.08 secs; Memory: 10MB
```
### Analise de padrão de código do projeto

Além da PSR-2 nós da Bleez podemos seguir algumas padronizações nossa de como o código deve ser escrito. Essa padronização será definido dentro do arquivo `.php_cs` na raíz do projeto. **Não altere ele a não ser que seja discutido e aprovado em conjunto sua alteração.**

Com o comando `composer check-cs` é possível verificar se há alguma quebra de padrão definidor dentro deste arquivo.

```bash
$ composer check-cs

> vendor/bin/php-cs-fixer fix --config .php_cs --using-cache=no -v --dry-run --stop-on-violation
Loaded config default from ".php_cs".
...............F

Legend: ?-unknown, I-invalid file syntax, file ignored, S-Skipped, .-no changes, F-fixed, E-error
   1) www/packages/module-shippings/src/Model/DescobridorDeAdapters.php (function_declaration, braces)

Checked all files in 0.593 seconds, 16.000 MB memory used
```

### Conserto de padrão de código

O comando `composer fix-cs` irá rodar dentro da pasta `/packages` e irá resolver a maioria dos conflitos de padrão de código, sejam PSR-2 ou do que foi definido em `.php_cs`.

Exemplo
```bash
$ composer fix-cs

> vendor/bin/php-cs-fixer fix --config .php_cs --using-cache=no
Loaded config default from ".php_cs".
   1) www/packages/module-shippings/src/Model/DescobridorDeAdapters.php

Fixed all files in 0.690 seconds, 16.000 MB memory used
```

Infelizmente este comando não consegue corrigir 100% dos conflitos de padrão, portanto para garantir que está tudo correto use os comandos `composer check-psr2` e `composer check-cs`.
