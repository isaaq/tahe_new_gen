class BaseUI
  attr_accessor :size, :properties, :shape, :flags, :redraw_on_mouse, :widgets_up, :widgets_start_y, :clip_area,
                :resizable, :horizontal, :slots, :title_color, :shape

  EVENTS = %w[onAdded onRemoved onStart onStop onDrawBackground onDrawForeground onMouseDown onMouseMove onMouseUp
              onMouseEnter onMouseLeave onDblClick onExecute onPropertyChanged onGetInputs onGetOutputs onSerialize onSelected onDeselected onDropItem onDropFile onConnectInput onConnectionsChange]
end
