# frozen_string_literal: true

module Chamomile
  # Instance methods for building layout trees from view.
  # Included by Application — all methods run in the model's own context,
  # so @ivars, quit, tick, etc. work naturally.
  module ViewDSL
    def vertical(align: :left, &block)
      layout = Layout::Vertical.new(align: align)
      _layout_stack.push(layout)
      yield
      _layout_stack.pop
      _layout_stack.empty? ? layout : (_layout_stack.last.add(layout) && nil)
    rescue StandardError
      _layout_stack.pop
      raise
    end

    def horizontal(align: :top, &block)
      layout = Layout::Horizontal.new(align: align)
      _layout_stack.push(layout)
      yield
      _layout_stack.pop
      _layout_stack.empty? ? layout : (_layout_stack.last.add(layout) && nil)
    rescue StandardError
      _layout_stack.pop
      raise
    end

    def panel(title: nil, width: nil, border: :rounded, color: nil, focused: false, &block)
      widget = Layout::Panel.new(title: title, width: width, border: border,
                                 color: color, focused: focused)
      _layout_stack.push(widget)
      block.call if block_given?
      _layout_stack.pop
      _layout_stack.empty? ? widget : (_layout_stack.last.add(widget) && nil)
    rescue StandardError
      _layout_stack.pop
      raise
    end

    def text(content, **opts)
      _add_to_stack(Layout::Text.new(content, **opts))
    end

    def list(items, **opts)
      _add_to_stack(Layout::List.new(items, **opts))
    end

    def table(data, **opts)
      _add_to_stack(Layout::Table.new(data, **opts))
    end

    def status_bar(content, **opts)
      _add_to_stack(Layout::StatusBar.new(content, **opts))
    end

    def spinner(**opts)
      _add_to_stack(Layout::Spinner.new(**opts))
    end

    def raw(string)
      _add_to_stack(Layout::Raw.new(string))
    end

    private

    def _layout_stack
      @_layout_stack ||= []
    end

    def _add_to_stack(widget)
      if _layout_stack.empty?
        widget
      else
        _layout_stack.last.add(widget)
        nil
      end
    end
  end
end
