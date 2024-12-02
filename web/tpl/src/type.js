function fetchJS() {
    $.get('/api/ui/types', r => {
        r.data.forEach(e => {
            eval(e.content)
        });
    })

}
fetchJS();

LGraphNode.prototype.addMultilineWidget = function(node, name, val, opts) {
    const inEl = document.createElement('textarea');
    inEl.className = 'multiline-input';
    inEl.value = opts.defaultVal;
    inEl.placeholder = opts.placeholder || name;
    const widget = this.addDomWidget(node, 'customtext', inEl, {getValue() {return inEl.value}, setValue(v) {inEl.value = v}})
    widget.inputEl = inEl;
    inEl.addEventListener('input', () => {widget.callback?.(widget.value)});
    return {minWidth: 400, minHeight: 200, widget};
}

LGraphNode.prototype.addDomWidget = function (name,type,element,options) {
    options = { hideOnZoom: true, selectOn: ['focus', 'click'], ...options }
    let body = document.getElementsByTagName("body")[0]
    if (!element.parentElement) {
      body.append(element)
    }
    // element.hidden = true
    // element.style.display = 'none'
  
    let mouseDownHandler
    if (element.blur) {
      mouseDownHandler = (event) => {
        if (!element.contains(event.target)) {
          element.blur()
        }
      }
      document.addEventListener('mousedown', mouseDownHandler)
    }
  
    // const { nodeData } = this.constructor
    // const tooltip = (nodeData?.input.required?.[name] ??
    //   nodeData?.input.optional?.[name])?.[1]?.tooltip
    // if (tooltip && !element.title) {
    //   element.title = tooltip
    // }
  
    const widget = {
      type,
      name,
      get value() {
        return options.getValue?.() ?? undefined
      },
      set value(v) {
        options.setValue?.(v)
        widget.callback?.(widget.value)
      },
      draw: function (ctx,node,widgetWidth,y,widgetHeight) {
        if (widget.computedHeight == null) {
        //   computeSize.call(node, node.size)
        }
  
        const hidden =
          widget.computedHeight <= 0 ||
          widget.type === 'converted-widget' ||
          widget.type === 'hidden'
        element.dataset.shouldHide = hidden ? 'true' : 'false'
        const isInVisibleNodes = element.dataset.isInVisibleNodes === 'true'
        const isCollapsed = element.dataset.collapsed === 'true'
        const actualHidden = hidden || !isInVisibleNodes || isCollapsed
        const wasHidden = element.hidden
        element.hidden = actualHidden
        element.style.display = actualHidden ? 'none' : null
        if (actualHidden && !wasHidden) {
          widget.options.onHide?.(widget)
        }
        if (actualHidden) {
          return
        }
  
        const margin = 10
        const elRect = ctx.canvas.getBoundingClientRect()
        const transform = new DOMMatrix()
          .scaleSelf(
            elRect.width / ctx.canvas.width,
            elRect.height / ctx.canvas.height
          )
          .multiplySelf(ctx.getTransform())
          .translateSelf(margin, margin + y)
  
        const scale = new DOMMatrix().scaleSelf(transform.a, transform.d)
  
        Object.assign(element.style, {
          transformOrigin: '0 0',
          transform: scale,
          left: `${transform.a + transform.e}px`,
          top: `${transform.d + transform.f}px`,
          width: `${widgetWidth - margin * 2}px`,
          height: `${(widget.computedHeight ?? 50) - margin * 2}px`,
          position: 'absolute',
        //   zIndex: app.graph.nodes.indexOf(node),
        //   pointerEvents: app.canvas.read_only ? 'none' : 'auto'
        })
  
        if (enableDomClipping) {
          element.style.clipPath = getClipPath(node, element, elRect)
          element.style.willChange = 'clip-path'
        }
  
        this.options.onDraw?.(widget)
      },
      element,
      options,
      onRemove() {
        if (mouseDownHandler) {
          document.removeEventListener('mousedown', mouseDownHandler)
        }
        element.remove()
      }
    }
  
    // for (const evt of options.selectOn) {
    //   element.addEventListener(evt, () => {
    //     body.canvas.selectNode(this)
    //     body.canvas.bringToFront(this)
    //   })
    // }
  
    this.addCustomWidget(widget)
    this.widgets.push(widget)
  
    const collapse = this.collapse
    this.collapse = function () {
      collapse.apply(this, arguments)
      if (this.flags?.collapsed) {
        element.hidden = true
        element.style.display = 'none'
      }
      element.dataset.collapsed = this.flags?.collapsed ? 'true' : 'false'
    }
  
    const onRemoved = this.onRemoved
    this.onRemoved = function () {
      element.remove()
      elementWidgets.delete(this)
      onRemoved?.apply(this, arguments)
    }
  
    if (!this['SIZE']) {
      this['SIZE'] = true
      const onResize = this.onResize
      this.onResize = function (size) {
        options.beforeResize?.call(widget, this)
        // computeSize.call(this, size)
        onResize?.apply(this, arguments)
        options.afterResize?.call(widget, this)
      }
    }
  
    return widget
  }

function testTableType() {
    this.addOutput("输出", "");
    this.properties = {};
    // let that = this;
    this.text = this.addWidget("text", "Text", "名称", v=>{});
    
    this.addInput("search", "test/search");
    this.addInput("datasource", "test/ds");
    this.addInput("pager", "test/pager");
    this.addInput("ops", "test/op");
    this.serialize_widgets = true;
}
testTableType.title = "Table";
LiteGraph.registerNodeType("test/table", testTableType);

function testSearchType() {
    this.addOutput("输出", "")
    this.properties = {}
    // this.combo = this.addWidget("");
    this.serialize_widgets = true;
}
testSearchType.title = "Search";
LiteGraph.registerNodeType("test/search", testSearchType);

function testDatasourceType() {
    this.addOutput("输出", "")
    this.properties = {}
    this.text = this.addWidget("text", "Text", "名称", v=>{});
    this.model = this.addWidget("text", "Text", "模型", v=>{});
    this.query = this.addMultilineWidget("textarea", "Text", "策略", v=>{});
    this.serialize_widgets = true;
}
testDatasourceType.title = "Datasource";
LiteGraph.registerNodeType("test/ds", testDatasourceType);