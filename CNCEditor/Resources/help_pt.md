# CNC Editor 2D — Guia

Um aplicativo para preparar trabalhos 2D para uma fresadora CNC: desenhe ou abra vetores, calcule os percursos da fresa e salve o programa NC para a sua máquina.
- **Weihong / NcStudio**: arquivo **.tap**, um fuso.
- **Superstar (4 fusos)**: arquivo **.nc**. O número da ferramenta é o número do fuso.

## 1. Primeiros passos

### Tela inicial
- **Criar novo modelo**: defina o tamanho da chapa.
- **Abrir modelo**: DXF, SVG ou projeto .cnc2d.
- **Modelo a partir de imagem / foto**: uma foto da câmera ou da galeria vira fundo.
- **Voltar ao modelo**: aparece quando já há um modelo aberto.
- No topo, a escolha do **idioma** (🌐, 17 idiomas). Abaixo: **Guia**, **Premium** e links para outros apps da ARESTI Labs e o site.

### Tamanho do novo modelo
- **Largura (X)** e **Altura (Y)**: tamanho da peça bruta. Os botões 1830×2750, 2070×2800, 1220×2440, 2050×3050 colocam chapas padrão.
- **Origem do modelo**: toque num canto ou no centro do esquema. É o X0 Y0 da máquina, geralmente o canto inferior esquerdo.
- **Unidades**: mm ou polegadas. Tudo é guardado em milímetros.
- **Espessura do material**: usada nas profundidades.

## 2. Tela do editor

- **Barra de menus** (topo): 🏠 — voltar ao início; depois Arquivo, Editar, Modelo, Vetores, Percursos, Ajuda. Um item com ▸ abre submenu; «← Voltar» retorna.
- **Barra de visualização** (sob o menu):
  - ☰ — mostrar/ocultar o painel;
  - modelo inteiro, aproximar, afastar, grade;
  - desfazer, refazer;
  - **Seleção**, **Nós**, **Adicionar à seleção**;
  - ⟳ girar tela: paisagem → retrato → automático;
  - menu **Selecionar ▾**, menu de ações ⋮;
  - contador «Selecionados: N».
- **Painel** com três abas (embaixo no retrato, à esquerda na paisagem):
  - **Projeto**: informações, camadas, dicas de seleção, fundo;
  - **Assistente**: todas as ferramentas de desenho e edição; uma ferramenta aberta mostra aqui seus campos;
  - **Percursos**: lista, material, banco de ferramentas, cálculo e salvamento do programa NC.
- **Chapa**: o retângulo branco é a peça. Os traços vermelho e verde são os eixos X e Y no zero.
- A **dica** embaixo diz o que fazer agora. Se um ponto é esperado, há o botão «Cancelar».

Um toque longo num ícone mostra seu nome. Um ícone com canto ◢ é um grupo: tocar abre a lista das ferramentas. A última escolhida fica no botão.

## 3. Gestos na chapa

- **Um dedo num vetor**: selecionar.
- **Arrastar um vetor selecionado**: mover.
- **Alças quadradas nos cantos**: escala proporcional.
- **Alça redonda acima do quadro**: girar de 1° em 1°.
- **Arrastar num espaço vazio**: quadro de seleção.
  - **Da esquerda para a direita** (azul, contínuo): seleciona vetores totalmente dentro.
  - **Da direita para a esquerda** (verde, tracejado): seleciona todos que o quadro toca.
- **Tocar num espaço vazio**: desmarcar.
- **Dois dedos**: mover e zoom.
- **Toque longo num vetor**: ativa a seleção múltipla.
  - Cada toque seguinte adiciona ou remove um vetor.
  - Números em círculos rosa mostram a ordem. Ela importa: ao alinhar, a base é o último selecionado; ao subtrair, o último é subtraído.
- **Toque longo com vetores selecionados** (no vazio) abre o menu de ações.

Vetores selecionados são desenhados com uma linha rosa grossa com brilho; os fechados também com preenchimento leve.

## 4. Selecionar vários vetores (em vez de Shift)

- Botão **Adicionar à seleção**: enquanto ativo, cada toque adiciona ou remove; o quadro também adiciona.
- **Toque longo num vetor** ativa o mesmo modo temporariamente. Desliga com «Adicionar à seleção» ou «Desmarcar».
- Menu **Selecionar ▾**: tudo; todos na camada atual; só fechados, só abertos; tamanho semelhante (como a primeira amostra); inverter; desmarcar; lista de selecionados.
- **Lista de selecionados** (ou toque «Selecionados: N»): vetores em ordem com tamanho. ✕ remove um vetor da seleção.

## 5. Desenhar formas

Aba **Assistente** → «Ferramentas de vetor». Cada forma é desenhada de dois jeitos:
- **Com o dedo**: arraste na chapa; os campos mostram as medidas na hora.
- **Com números**: centro, largura, altura, raios etc. e toque «Criar / Pronto».

Enquanto a forma acabou de ser desenhada, mudar um campo a altera. «Pronto» a fixa. «Centro com toque» indica o centro tocando.

- **Retângulo**: largura, altura, raio dos cantos; arredondados ou invertidos (côncavos).
- **Círculo**: centro e raio ou diâmetro.
- **Elipse**: centro, largura, altura, ângulo.
- **Polígono**: número de lados, raio, rotação.
- **Estrela**: número de pontas, raios externo e interno.
- **Arco**, três modos: por três pontos; centro, início e fim; início, fim e raio.
- **Polilinha**: toque na chapa — cada toque adiciona um ponto. O próximo ponto pode ser digitado. «Fechar» liga ao primeiro ponto.

**Editar uma forma pronta**: selecione-a e ⋮ → «Editar forma / texto…».

## 6. Nós

Botão **Nós**: escolha um vetor e arraste seus pontos.
- Quadrados azuis = pontos, verde = ponto inicial, círculos = pontos de controle Bézier.
- **Toque longo num ponto**: excluir, suavizar, tornar inicial, digitar coordenadas.
- **Toque longo num trecho**: transformar em linha, arco ou curva Bézier; inserir ponto; inserir ponto inicial; excluir o trecho (cortar o vetor).

## 7. Editar vetores

Todos os comandos estão no menu **Vetores** e na seção do Assistente «Posição, combinar, aparar».
- **Transformar**: mover exato, tamanho (proporcional), girar, cisalhar, com ou sem cópia.
- **Espelhar**: horizontal ou vertical, em relação ao próprio centro ou à chapa.
- **Offset**: para fora ou para dentro numa distância; cantos vivos ou arredondados.
- **Cópia em bloco**: linhas e colunas com espaço ou passo. **Circular**: N cópias em volta de um centro.
- **Alinhar**: bordas e centros em relação ao último selecionado; «Centro da chapa» — em relação à peça.
- **Agrupar / Desagrupar**: um grupo é selecionado e movido inteiro.
- **Combinar fechados**: Weld (unir); Interseção; Subtrair (o último selecionado é subtraído); excluir parte comum.
- **Fechar**: com linha, curva ou movendo a extremidade. **Unir dois abertos**: com linha, curva ou movendo extremidades. **Pontos coincidentes**: junta muitos pedaços em cadeias com tolerância.
- **Doutor de vetores**: acha pontos coincidentes, autointerseções e laços e os corrige.
- **Arcos em vez de curvas**: troca Bézier por arcos e linhas (programa NC menor, corte mais limpo).
- **Arredondamento**: toque num canto, defina o raio. Aqui também: estender dois vetores até a interseção.
- **Tesoura (aparar)**: tocar num trecho apaga o pedaço entre interseções.
- **Recorte por contorno (Clipping)**: mantém vetores dentro ou fora do contorno escolhido.
- **Fatiar**: corta vetores com uma linha em X ou Y.
- **Moldura em volta**: retângulo em volta da seleção com margem.
- **Converter**: encontra círculos ou retângulos entre os vetores e os torna «formas».
- **Inverter direção**: importante para a ordem e o lado da usinagem.
- **Bloquear**: o vetor não se move por acidente.
- **Propriedades**: tamanho, comprimento, área, número de pontos, linhas, arcos e curvas.

## 8. Texto

**Texto vetorial**:
- fonte: tipo Arial, Times, Courier, DejaVu ou de traço único (gravação em uma linha);
- altura, negrito, itálico;
- alinhamento, espaçamento de letras e linhas, kerning;
- esticar, inclinar, girar;
- posição X/Y.

«Criar» coloca o texto na chapa. Depois selecione-o e altere via ⋮ → «Editar forma / texto».

**Texto na curva**: escolha uma curva ou círculo, abra «Texto na curva», ajuste o início, o afastamento e o lado. As letras seguem a curva.

## 9. Envelope e «Colar ao longo da curva»

- **Envelope**: escolha um desenho ou padrão e abra «Envelope». Surge um quadro com nós. Arraste cantos e meios dos lados. Ou toque «Curva superior…» / «Curva inferior…» e toque numa curva existente (um arco, por exemplo). «Aplicar» deforma o desenho — assim um padrão cabe num arco ou numa onda.
- **Colar ao longo da curva**: cópias do desenho são distribuídas por uma curva — por quantidade ou passo, girando com a curva ou não.

## 10. Placas e encaixe

- **Multi-Plate**: um modelo de placa (contorno + texto) se repete na chapa com as linhas de um arquivo de texto. Por exemplo números de apartamento ou nomes: uma linha, uma placa.
- **Encaixe (Nesting)**: as peças escolhidas são colocadas em chapas de tamanho dado, com espaço e margem. A rotação pode ser permitida. Os furos ficam automaticamente com a peça.

## 11. Imagens e fotos

- Menu **Arquivo → Importar imagem / foto** ou ícone «Imagem». Fonte: **galeria** ou **câmera**. A imagem vira um **fundo** semitransparente.
- **Ajustes do fundo**: opacidade, mostrar, bloquear. Tamanho em números ou **por dois pontos**: toque em dois pontos de distância conhecida e digite a distância real.
- **Contornar à mão**: desenhe com polilinha e formas sobre o fundo.
- **Vetorização** (ícone «Vetorizar»):
  1. Escolha o modo: preto e branco (silhueta por limiar) ou contornos.
  2. Ajuste o limiar (ou «auto»), suavização, remoção de manchas, inversão.
  3. «Pré-visualizar» mostra os futuros vetores sobre a imagem.
  4. «Criar vetores» adiciona-os ao modelo.
- **Corrigir perspectiva**: se a chapa foi fotografada inclinada, toque nos quatro cantos e digite o tamanho real. A foto fica reta e na escala 1:1.
- **Pontes de estêncil**: pequenas ligações para o miolo das letras não cair.

## 12. Percursos (usinagem)

Etapas:
1. **Material** (aba Percursos → ícone de material): espessura, Z seguro, ponto de repouso (para onde a máquina vai no fim).
2. **Banco de ferramentas**: fresas com número, diâmetro, ângulo (fresas V), passo vertical e lateral, rotação, avanço e velocidade de mergulho. Avanço em mm/s ou mm/min. Adicione, copie, edite e exclua; o banco fica no telefone.
3. **Selecione vetores** e toque o tipo de usinagem.

### Tipos de usinagem
- **Perfil**: corte por fora ou por dentro do contorno (com o raio da fresa) ou na linha. Ajustes: profundidade inicial e final; sobremetal; direção (concordante ou discordante); ordem.
- **Pontes (fixadores)**: as peças não se soltam no corte. Automáticas (por quantidade ou distância) ou manuais tocando no contorno. Comprimento e altura ajustáveis.
- **Mergulho em rampa**: a fresa entra inclinada, não na vertical — menos carga e marcas.
- **Ao longo dos vetores**: a fresa passa exatamente na linha. Para gravação, canais, texto de traço único.
- **Desbaste de área**: bolsão dentro de um contorno. Passadas por offset (seguindo o contorno) ou raster (zigue-zague), com sobreposição definida.
- **Gravação em V**: fresa V; a profundidade segue a largura da linha, gerando letras e padrões «entalhados».
- **Furação**: furos nos centros dos círculos, com quebra de cavaco (passo de furação).

Na seção «Ferramenta», toque **Escolher…** para pegar uma fresa do banco. **Calcular** cria o percurso. Abaixo aparecem comprimento de corte, número de mergulhos e tempo estimado.

Lista de percursos: tocar seleciona o percurso e seus vetores; caixa — mostrar/ocultar; «Alterar…» — parâmetros; «Recalcular» — após mudar vetores; «Excluir».

### Simulação
Ícone «Simulação»: vista superior de como a fresa passa pelo material. Iniciar/pausar, velocidade, «Resultado» (tudo de uma vez), «Do início». Bom para conferir pontes, cantos internos e falhas.

### Salvar o programa NC
**Percursos → Salvar percursos como…**:
1. Marque os percursos.
2. Escolha o pós-processador: **Weihong (.tap)** para NcStudio; **Superstar (.nc)** de 4 fusos, número da fresa 1–4 = número do fuso; **seu .con** — «Carregar seu próprio .con…», o arquivo do pós-processador da sua máquina (formato ArtCAM). Ele fica salvo.
3. Dê o nome. «Pré-visualizar» mostra o início do programa. «Salvar» — escolha a pasta (pendrive, por exemplo).

**Grátis**: 1 programa da máquina por dia. **Premium** (compra única) remove o limite e os anúncios.

**Dica**: antes do primeiro corte confira o zero e o Z na máquina e rode o programa primeiro «no ar» (com o Z levantado).

## 13. Salvar e exportar

- **Salvar (DXF)**: um DXF R12 comum abre em qualquer programa CAD/CAM. Dentro dele o projeto inteiro fica guardado de forma invisível: camadas, percursos, fresas, fundo. Ao abri-lo aqui, tudo volta.
- **Salvar como**: DXF; SVG (as camadas abrem como camadas no Inkscape); projeto .cnc2d.
- **Exportar**: PDF 1:1 (para imprimir gabarito); PNG ou JPG na resolução escolhida, PNG também com fundo transparente.
- **Importar vetores**: adiciona vetores de outro DXF ou SVG ao modelo.
- DXF na antiga codificação Windows-1251 (cirílico do ArtCAM/AutoCAD) abre corretamente.

## 14. Camadas

Aba **Projeto** → Camadas, ou **Editar → Camadas…**: adicionar; renomear ✎; cor; mostrar/ocultar 👁; bloquear 🔒; excluir ✕.

Vetores novos vão para a camada **ativa** (destacada). «Mover» leva os vetores selecionados para a camada ativa.

## 15. Desfazer e botão Voltar

- **Desfazer / Refazer**: até 80 passos.
- O botão **Voltar** do sistema, em ordem: cancela a escolha de ponto; fecha a ferramenta aberta; fecha uma janela; volta ao início (pergunta se o modelo não foi salvo).

## 16. Importar código G (.tap, .nc)

A app abre um programa de máquina pronto (.tap, .nc, .ngc, .gcode, etc.) e recupera dele o desenho.
- Abra o ficheiro: **Abrir modelo** no ecrã inicial (modelo novo) ou **Ficheiro → Importar vetores…** (adicionar ao atual).
- **Compensação da fresa**: o programa guarda o percurso do centro da fresa.
  - «Nenhuma» — vetores pelo centro da fresa (para gravação e maquinagem ao longo de vetores);
  - «Auto» — as peças deslocam-se para dentro e os furos para fora pelo raio da fresa;
  - «Todos para dentro» / «Todos para fora». Indique o diâmetro da fresa.
- **Unir passagens de profundidade** — várias passagens a profundidades diferentes tornam-se um contorno.
- **Cada ferramenta na sua camada** — camadas T1, T2… se o programa usar várias fresas.
- Depois guarde o desenho: **Ficheiro → Guardar (DXF)**, edite-o ou calcule novos percursos.

## 17. Perguntas frequentes

- **O percurso não é calculado:** perfil por fora/dentro e desbaste exigem vetores **fechados** — use «Doutor de vetores» ou «Unir pontos coincidentes»; a fresa pode ser mais larga que o bolsão.
- **A peça é cortada do lado errado:** confira fora/dentro e a direção do vetor («Inverter direção»).
- **Letras caem ao cortar um estêncil:** use «Pontes de estêncil» ou as pontes do perfil.
- **A máquina «desloca»:** confira a origem do modelo (Modelo → Posição do zero) e o ponto de repouso em Material.
- **É difícil tocar vetores pequenos:** aproxime com dois dedos ou use um quadro da direita para a esquerda.
