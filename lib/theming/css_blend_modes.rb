require 'gtk4'

class CssBlendModesDemo
  ASSETS = File.expand_path('../../demos/gtk-demo', __dir__).freeze

  BLEND_MODES = [
    ['Color', 'color'],
    ['Color (burn)', 'color-burn'],
    ['Color (dodge)', 'color-dodge'],
    ['Darken', 'darken'],
    ['Difference', 'difference'],
    ['Exclusion', 'exclusion'],
    ['Hard Light', 'hard-light'],
    ['Hue', 'hue'],
    ['Lighten', 'lighten'],
    ['Luminosity', 'luminosity'],
    ['Multiply', 'multiply'],
    ['Normal', 'normal'],
    ['Overlay', 'overlay'],
    ['Saturate', 'saturation'],
    ['Screen', 'screen'],
    ['Soft Light', 'soft-light']
  ].freeze

  DEFAULT_MODE = 'normal'.freeze

  # page name, title, and the [css class, caption] pairs the page shows
  PAGES = [
    ['page0', 'Ducky', [['duck', 'Duck'], ['gradient', 'Background']], 'blend0'],
    ['page1', 'Blends', [['red', 'Red'], ['blue', 'Blue']], 'blend1'],
    ['page2', 'CMYK', [['cyan', 'Cyan'], ['magenta', 'Magenta'], ['yellow', 'Yellow']], 'blend2']
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'CSS Blend Modes'
          win.resizable = false
          win.set_default_size(400, 300)
          win.child = grid
        end

        grid.tap do |g|
          g.attach(mode_label, 0, 0, 1, 1)
          g.attach(scrolled_window, 0, 1, 1, 1)
          g.attach(stack_switcher, 1, 0, 1, 1)
          g.attach(stack, 1, 1, 1, 1)

          scrolled_window.tap { |sw| sw.child = list_box }

          stack_switcher.tap { |switcher| switcher.stack = stack }

          stack.tap do |s|
            PAGES.each do |name, title, swatches, blend_class|
              s.add_titled(blend_page(swatches, blend_class), name, title)
            end
          end

          list_box.tap do |box|
            BLEND_MODES.each { |name, _| box.append(mode_row(name)) }

            box.signal_connect('row-activated') do |_, row|
              apply_blend_mode(BLEND_MODES[row.index][1])
            end
          end
        end

        Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, PRIORITY)
        apply_blend_mode(DEFAULT_MODE)
        select_default_row

        window.present
      end
    end
  end

  PRIORITY = Gtk::StyleProvider::PRIORITY_APPLICATION

  def app = @app ||= Gtk::Application.new('org.example.css_blend_modes', :default_flags)
  def window = @window ||= Gtk::Window.new
  def stack_switcher = @stack_switcher ||= Gtk::StackSwitcher.new.tap { |s| s.halign = :center; s.hexpand = true }
  def list_box = @list_box ||= Gtk::ListBox.new
  def provider = @provider ||= Gtk::CssProvider.new

  # The CSS carries three printf placeholders, one per blended image.
  def css_template
    @css_template ||= File.read(File.join(ASSETS, 'css_blendmodes.css'))
                          .gsub(%r{resource://[\w/\-.]*?/([\w\-.]+)}) { "file://#{File.join(ASSETS, Regexp.last_match(1))}" }
  end

  def grid
    @grid ||= Gtk::Grid.new.tap do |g|
      g.margin_start = 12
      g.margin_end = 12
      g.margin_top = 12
      g.margin_bottom = 12
      g.row_spacing = 12
      g.column_spacing = 12
    end
  end

  def mode_label
    @mode_label ||= Gtk::Label.new('Blend mode:').tap do |l|
      l.xalign = 0
      l.add_css_class('dim-label')
    end
  end

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.vexpand = true
      sw.has_frame = true
      sw.min_content_width = 150
    end
  end

  def stack
    @stack ||= Gtk::Stack.new.tap do |s|
      s.hexpand = true
      s.vexpand = true
      s.hhomogeneous = false
      s.vhomogeneous = false
      s.transition_type = :crossfade
    end
  end

  private

  def mode_row(name)
    Gtk::ListBoxRow.new.tap do |row|
      row.child = Gtk::Label.new(name).tap { |l| l.xalign = 0 }
    end
  end

  def blend_page(swatches, blend_class)
    Gtk::Grid.new.tap do |g|
      g.halign = :center
      g.valign = :center
      g.vexpand = true
      g.row_spacing = 12
      g.column_spacing = 12

      swatches.each_with_index do |(css_class, caption), column|
        g.attach(Gtk::Label.new(caption), column, 0, 1, 1)
        g.attach(swatch(css_class), column, 1, 1, 1)
      end

      g.attach(Gtk::Label.new("\nBlended picture"), 0, 2, swatches.size, 1)
      g.attach(swatch(blend_class).tap { |i| i.halign = :center }, 0, 3, swatches.size, 1)
    end
  end

  def swatch(css_class) = Gtk::Image.new.tap { |image| image.add_css_class(css_class) }

  def apply_blend_mode(mode)
    provider.load(string: format(css_template, mode, mode, mode))
  end

  def select_default_row
    BLEND_MODES.index { |_, id| id == DEFAULT_MODE }.then do |index|
      list_box.get_row_at_index(index).tap do |row|
        list_box.select_row(row)
        row.grab_focus
      end
    end
  end
end

CssBlendModesDemo.new.build.run
