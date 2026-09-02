require 'gtk4'

class DecorativeOverlayDemo
  ASSETS = File.expand_path('../../demos/gtk-demo', __dir__).freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Decorative Overlay'
          win.set_default_size(500, 510)
          win.child = overlay
        end

        overlay.tap do |o|
          o.child = scrolled_window
          o.add_overlay(top_left_decor)
          o.add_overlay(bottom_right_decor)
          o.add_overlay(margin_scale)

          scrolled_window.tap { |sw| sw.child = text_view }

          margin_scale.tap do |scale|
            scale.adjustment.signal_connect('value-changed') { apply_margin(scale.adjustment.value.to_i) }
          end
        end

        apply_margin(100)
        margin_scale.adjustment.value = 100

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.overlay_decorative', :default_flags)
  def window = @window ||= Gtk::Window.new
  def overlay = @overlay ||= Gtk::Overlay.new
  def top_left_decor = @top_left_decor ||= decor('decor1.png', :start, :start)
  def bottom_right_decor = @bottom_right_decor ||= decor('decor2.png', :end, :end)

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap { |sw| sw.set_policy(:automatic, :automatic) }
  end

  def text_view
    @text_view ||= Gtk::TextView.new.tap do |view|
      view.buffer.text = 'Dear diary...'
    end
  end

  # Applies to the first word only, so the tag's extra leading is visible.
  def top_margin_tag
    @top_margin_tag ||= text_view.buffer.create_tag('top-margin', 'pixels-above-lines' => 0).tap do |tag|
      text_view.buffer.apply_tag(tag, text_view.buffer.start_iter, first_word_end)
    end
  end

  def margin_scale
    @margin_scale ||= Gtk::Scale.new(:horizontal, Gtk::Adjustment.new(0, 0, 100, 1, 1, 0)).tap do |scale|
      scale.draw_value = false
      scale.set_size_request(120, -1)
      scale.margin_start = 20
      scale.margin_end = 20
      scale.margin_bottom = 20
      scale.halign = :start
      scale.valign = :end
      scale.tooltip_text = 'Margin'
    end
  end

  private

  def first_word_end
    text_view.buffer.start_iter.tap { |iter| iter.forward_word_end }
  end

  def decor(file, halign, valign)
    Gtk::Picture.new(File.join(ASSETS, file)).tap do |picture|
      picture.can_target = false
      picture.halign = halign
      picture.valign = valign
    end
  end

  def apply_margin(value)
    text_view.left_margin = value
    top_margin_tag.set_property('pixels-above-lines', value)
  end
end

DecorativeOverlayDemo.new.build.run
