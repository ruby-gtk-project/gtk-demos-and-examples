require 'gtk4'

class MarkupDemo
  MARKUP_FILE = File.expand_path('../../demos/gtk-demo/markup.txt', __dir__).freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Markup'
          win.set_default_size(600, 680)
          win.titlebar = header_bar
          win.child = stack
        end

        header_bar.tap { |header| header.pack_start(source_button) }

        source_button.tap do |btn|
          btn.signal_connect('toggled') { btn.active? ? show_source : show_formatted }
        end

        stack.tap do |s|
          s.add_named(formatted_scroller, 'formatted')
          s.add_named(source_scroller, 'source')

          formatted_scroller.tap { |sw| sw.child = formatted_view }
          source_scroller.tap { |sw| sw.child = source_view }
        end

        load_markup

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.markup', :default_flags)
  def window = @window ||= Gtk::Window.new
  def header_bar = @header_bar ||= Gtk::HeaderBar.new
  def stack = @stack ||= Gtk::Stack.new
  def formatted_scroller = @formatted_scroller ||= scroller
  def source_scroller = @source_scroller ||= scroller
  def markup = @markup ||= File.read(MARKUP_FILE)

  def source_button
    @source_button ||= Gtk::CheckButton.new.tap do |btn|
      btn.label = 'Source'
      btn.valign = :center
    end
  end

  def formatted_view
    @formatted_view ||= Gtk::TextView.new.tap do |tv|
      tv.editable = false
      tv.wrap_mode = :word_char
      tv.left_margin = 10
      tv.right_margin = 10
    end
  end

  def source_view
    @source_view ||= Gtk::TextView.new.tap do |tv|
      tv.wrap_mode = :word
      tv.left_margin = 10
      tv.right_margin = 10
    end
  end

  private

  def scroller
    Gtk::ScrolledWindow.new.tap { |sw| sw.set_policy(:automatic, :automatic) }
  end

  def load_markup
    formatted_view.buffer.tap do |buffer|
      buffer.begin_irreversible_action
      buffer.insert_markup(buffer.start_iter, markup)
      buffer.end_irreversible_action
    end

    source_view.buffer.tap do |buffer|
      buffer.begin_irreversible_action
      buffer.insert(buffer.start_iter, markup)
      buffer.end_irreversible_action
    end
  end

  def show_source = stack.visible_child_name = 'source'

  # Re-renders whatever the user typed in the source view as Pango markup.
  def show_formatted
    formatted_view.buffer.tap do |buffer|
      buffer.begin_irreversible_action
      buffer.delete(buffer.start_iter, buffer.end_iter)
      buffer.insert_markup(buffer.start_iter, source_view.buffer.text)
      buffer.end_irreversible_action
    end

    stack.visible_child_name = 'formatted'
  end
end

MarkupDemo.new.build.run
