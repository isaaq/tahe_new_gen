# KR 网格布局系统
# 基于 GridStack.js 思想，布局与内容完全分离
# 只负责网格布局，内容区域挂载 KR 标签

class KrGridLayout
  
  def self.generate(layout_config)
    generator = new(layout_config)
    generator.generate
  end
  
  def initialize(layout_config)
    @config = layout_config
    @grid_items = []
  end
  
  def generate
    parse_grid_items
    
    {
      html: generate_html,
      css: generate_css,
      js: generate_js
    }
  end
  
  private
  
  def parse_grid_items
    @config[:items]&.each do |item|
      @grid_items << {
        id: item[:id],
        x: item[:x] || 0,
        y: item[:y] || 0,
        w: item[:w] || 1,
        h: item[:h] || 1,
        content: item[:content] || '',
        css_class: item[:css_class] || '',
        resizable: item[:resizable] != false,
        draggable: item[:draggable] != false
      }
    end
  end
  
  def generate_html
    # 生成简化的配置数据，不包含内容
    simplified_config = {
      columns: @config[:columns],
      cellHeight: @config[:cellHeight],
      margin: @config[:margin],
      items: @grid_items.map do |item|
        {
          id: item[:id],
          x: item[:x],
          y: item[:y],
          w: item[:w],
          h: item[:h],
          resizable: item[:resizable],
          draggable: item[:draggable]
        }
      end
    }
    
    html = []
    html << %(<div class="kr-grid-layout" data-grid-config='#{simplified_config.to_json}'>)
    
    @grid_items.each do |item|
      html << generate_grid_item_html(item)
    end
    
    html << '</div>'
    html.join("\n")
  end
  
  def generate_grid_item_html(item)
    <<~HTML
      <div class="kr-grid-item #{item[:css_class]}" 
           data-gs-id="#{item[:id]}"
           data-gs-x="#{item[:x]}" 
           data-gs-y="#{item[:y]}" 
           data-gs-w="#{item[:w]}" 
           data-gs-h="#{item[:h]}"
           data-gs-resizable="#{item[:resizable]}"
           data-gs-draggable="#{item[:draggable]}">
        <div class="kr-grid-item-content">
          #{item[:content]}
        </div>
      </div>
    HTML
  end
  
  def generate_css
    <<~CSS
      .kr-grid-layout {
        position: relative;
        width: 100%;
        min-height: 400px;
      }
      
      .kr-grid-item {
        position: absolute;
        border: 1px solid #e6e6e6;
        border-radius: 4px;
        background: #fff;
        overflow: visible;  /* 修改为可见，允许内容扩展 */
        display: flex;     /* 使用flex布局 */
        flex-direction: column;
      }
      
      .kr-grid-item-content {
        padding: 15px;
        flex: 1;  /* 填充可用空间 */
        min-height: 0;  /* 防止内容溢出 */
        overflow: visible;  /* 允许内容扩展 */
      }
      
      /* 设计器模式样式 */
      .kr-grid-layout.designer-mode .kr-grid-item {
        border: 2px dashed #409eff;
        cursor: move;
      }
      
      .kr-grid-layout.designer-mode .kr-grid-item:hover {
        border-color: #67c23a;
        box-shadow: 0 2px 8px rgba(103, 194, 58, 0.3);
      }
      
      .kr-grid-layout.designer-mode .kr-grid-item.selected {
        border-color: #f56c6c;
        box-shadow: 0 2px 8px rgba(245, 108, 108, 0.3);
      }
    CSS
  end
  
  def generate_js
    <<~JS
      // KR 网格布局初始化
      (function() {
        const gridLayout = document.querySelector('.kr-grid-layout');
        if (!gridLayout) return;
        
        const config = JSON.parse(gridLayout.getAttribute('data-grid-config') || '{}');
        
        // 计算元素的实际高度
        function calculateContentHeight(element) {
          // 临时显示元素以测量高度
          const tempStyle = element.style;
          const originalDisplay = tempStyle.display;
          const originalVisibility = tempStyle.visibility;
          const originalPosition = tempStyle.position;
          
          tempStyle.display = 'block';
          tempStyle.visibility = 'hidden';
          tempStyle.position = 'absolute';
          
          // 添加到DOM中（如果尚未添加）
          const wasInDOM = element.parentNode;
          if (!wasInDOM) {
            document.body.appendChild(element);
          }
          
          // 获取高度
          const height = element.scrollHeight;
          
          // 恢复原始状态
          tempStyle.display = originalDisplay;
          tempStyle.visibility = originalVisibility;
          tempStyle.position = originalPosition;
          
          if (!wasInDOM) {
            document.body.removeChild(element);
          }
          
          return height;
        }

        // 初始化网格项位置
        function initGridItems() {
          const items = gridLayout.querySelectorAll('.kr-grid-item');
          const cellWidth = gridLayout.offsetWidth / (config.columns || 12);
          const cellHeight = config.cellHeight || 60;
          
          items.forEach(item => {
            const x = parseInt(item.getAttribute('data-gs-x')) || 0;
            const y = parseInt(item.getAttribute('data-gs-y')) || 0;
            const w = parseInt(item.getAttribute('data-gs-w')) || 1;
            let h = parseInt(item.getAttribute('data-gs-h')) || 1;
            
            // 计算内容高度
            const content = item.querySelector('.kr-grid-item-content');
            if (content) {
              const contentHeight = calculateContentHeight(content);
              // 计算最小需要的行数
              const minRows = Math.ceil((contentHeight + 30) / cellHeight); // 30px 为内边距和边框
              h = Math.max(h, minRows);
            }
            
            item.style.left = (x * cellWidth) + 'px';
            item.style.top = (y * cellHeight) + 'px';
            item.style.width = (w * cellWidth) + 'px';
            item.style.height = 'auto'; // 自动高度
            item.style.minHeight = (h * cellHeight) + 'px'; // 设置最小高度
          });
          
          // 触发窗口resize事件，让其他组件重新布局
          window.dispatchEvent(new Event('resize'));
        }
        
        // 设计器模式切换
        window.toggleDesignerMode = function() {
          gridLayout.classList.toggle('designer-mode');
        };
        
        // 获取布局配置
        window.getGridConfig = function() {
          const items = [];
          gridLayout.querySelectorAll('.kr-grid-item').forEach(item => {
            items.push({
              id: item.getAttribute('data-gs-id'),
              x: parseInt(item.getAttribute('data-gs-x')),
              y: parseInt(item.getAttribute('data-gs-y')),
              w: parseInt(item.getAttribute('data-gs-w')),
              h: parseInt(item.getAttribute('data-gs-h'))
            });
          });
          return { items };
        };
        
        // 初始化
        document.addEventListener('DOMContentLoaded', function() {
          // 延迟执行，确保所有内容已加载
          setTimeout(initGridItems, 100);
          
          // 监听内容变化
          const observer = new MutationObserver(function(mutations) {
            initGridItems();
          });
          
          // 开始观察目标节点
          const config = { childList: true, subtree: true };
          observer.observe(gridLayout, config);
        });
        
        // 响应式调整
        let resizeTimer;
        window.addEventListener('resize', function() {
          clearTimeout(resizeTimer);
          resizeTimer = setTimeout(initGridItems, 250);
        });
      })();
    JS
  end
end
