# Como Criar uma Animação de Sidebar "Meio Elástica" no Flutter (Web/Desktop)

Para criar aquele efeito premium onde a sidebar fica recolhida mostrando apenas a logo "OS" (ou, no seu caso, ícones) e, ao colocar o mouse por cima (`hover`), ela expande com um efeito de tração elástica (overshoot/bounce), utilizamos três ferramentas principais do Flutter:

1. **`MouseRegion`**: Para detectar a entrada e saída do mouse.
2. **`AnimatedContainer`**: Para interpolar o tamanho da Sidebar automaticamente sem precisar gerenciar um `AnimationController` complexo.
3. **`Curves.easeOutBack` ou `Curves.elasticOut`**: As curvas matemáticas que dão a sensação "elástica".

---

## Exemplo Prático (Código Dart)

Abaixo está o código de um `StatefulWidget` que serve como base para a sua Barra Lateral:

```dart
import 'package:flutter/material.dart';

class HoverElasticSidebar extends StatefulWidget {
  @override
  _HoverElasticSidebarState createState() => _HoverElasticSidebarState();
}

class _HoverElasticSidebarState extends State<HoverElasticSidebar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Definimos os tamanhos da barra
    final double minWidth = 70.0;
    final double maxWidth = 240.0;

    return MouseRegion(
      // Detecta quando o mouse entra na área da sidebar
      onEnter: (_) => setState(() => _isHovered = true),
      // Detecta quando o mouse sai da área
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        // Tempo da animação (em torno de 500-600ms fica natural para efeitos elásticos)
        duration: const Duration(milliseconds: 600),
        
        // A "mágica" elástica está aqui. 
        // easeOutBack ultrapassa o ponto final e volta suavemente, dando o efeito "meio elástico".
        // Se quiser um elástico bem mais saltitante, troque para: Curves.elasticOut
        curve: Curves.easeOutBack, 
        
        width: _isHovered ? maxWidth : minWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Fundo dark style (Tailwind slate-900)
          border: Border(
            right: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(4, 0),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Header da Sidebar (Logo) centralizada
            Center(child: _buildLogo()),
            
            const SizedBox(height: 48),
            // Itens do menu
            _buildMenuItem(Icons.dashboard_rounded, "Dashboard"),
            _buildMenuItem(Icons.shopping_bag_rounded, "Pedidos B2B"),
            _buildMenuItem(Icons.inventory_2_rounded, "Estoque"),
          ],
        ),
      ),
    );
  }

  // Constrói a Logo animada (Transição suave entre "OS" e "Delivery OS")
  Widget _buildLogo() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _isHovered
          ? const Text(
              "Delivery OS",
              key: ValueKey('expandedLogo'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            )
          : const Text(
              "OS",
              key: ValueKey('collapsedLogo'),
              style: TextStyle(
                color: Colors.blueAccent, // Destaque na versão menor
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }

  // Evita overflow dos textos ao fechar a barra e anima o fadeIn
  Widget _buildMenuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 22.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 26),
          const SizedBox(width: 16),
          // Ocupa o resto do espaço e só renderiza se estiver hovered 
          // para não dar erro visual enquanto a barra retrai
          if (_isHovered) 
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

## Explicação para passar a outras IAs (Prompt Engineering)

Se você for adicionar essas orientações no seu assistente de programação (como Cursor, Claude, etc.), pode utilizar o seguinte resumo para que ele gere com exatidão:

> "Para a Sidebar no Flutter (Desktop/Web), implemente o comportamento `Smart Hover` com efeito meio elástico. 
> 1. Envolva a sidebar em um widget `MouseRegion` e atualize o estado local (ex: `_isHovered = true/false`).
> 2. Use `AnimatedContainer` alterando o `width` (ex: de 70px para 240px). 
> 3. É **OBRIGATÓRIO** utilizar o `curve: Curves.easeOutBack` e `duration: 600ms` para criar o arrasto meio elástico, sem ser agressivo demais. 
> 4. Trate o comportamento da logo com um `AnimatedSwitcher`, mostrando 'OS' recolhido e 'Delivery OS' expandido.
> 5. Para evitar exceções de tela (RenderFlex overflow) durante a retração elástica, garanta que os textos do menu só sofram renderização condicional/expandida se a sidebar estiver estendida, usando `AnimatedOpacity` visível apenas no hover."
