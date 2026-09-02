require 'gtk4'

class SizeGroupsDemo
  COLOR_OPTIONS = %w[Red Green Blue].freeze
  DASH_OPTIONS = %w[Solid Dashed Dotted].freeze
  END_OPTIONS = ['Square', 'Round', 'Double Arrow'].freeze

  COLOR_ROWS = [['_Foreground', COLOR_OPTIONS], ['_Background', COLOR_OPTIONS]].freeze
  LINE_ROWS = [['_Dashing', DASH_OPTIONS], ['_Line ends', END_OPTIONS]].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Size Groups'
          win.resizable = false
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(color_frame)
          box.append(line_frame)
          box.append(grouping_button)

          color_frame.tap { |f| f.child = color_grid }
          line_frame.tap { |f| f.child = line_grid }

          color_grid.tap { |g| COLOR_ROWS.each_with_index { |row, i| add_row(g, i, *row) } }
          line_grid.tap { |g| LINE_ROWS.each_with_index { |row, i| add_row(g, i, *row) } }

          grouping_button.tap do |btn|
            btn.signal_connect('toggled') do
              size_group.mode = btn.active? ? :horizontal : :none
            end
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.size_groups', :default_flags)
  def window = @window ||= Gtk::Window.new
  def color_frame = @color_frame ||= Gtk::Frame.new('Color Options')
  def line_frame = @line_frame ||= Gtk::Frame.new('Line Options')
  def color_grid = @color_grid ||= options_grid
  def line_grid = @line_grid ||= options_grid
  def size_group = @size_group ||= Gtk::SizeGroup.new(:horizontal)

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 5).tap do |box|
      box.margin_start = 5
      box.margin_end = 5
      box.margin_top = 5
      box.margin_bottom = 5
    end
  end

  def grouping_button
    @grouping_button ||= Gtk::CheckButton.new.tap do |btn|
      btn.label = '_Enable grouping'
      btn.use_underline = true
      btn.active = true
    end
  end

  private

  def options_grid
    Gtk::Grid.new.tap do |g|
      g.margin_start = 5
      g.margin_end = 5
      g.margin_top = 5
      g.margin_bottom = 5
      g.row_spacing = 5
      g.column_spacing = 10
    end
  end

  def add_row(grid, row, label_text, options)
    Gtk::DropDown.new(options).tap do |dropdown|
      dropdown.halign = :end
      dropdown.valign = :baseline_fill
      size_group.add_widget(dropdown)
      grid.attach(dropdown, 1, row, 1, 1)

      Gtk::Label.new(label_text).tap do |label|
        label.use_underline = true
        label.halign = :start
        label.valign = :baseline_fill
        label.hexpand = true
        label.mnemonic_widget = dropdown
        grid.attach(label, 0, row, 1, 1)
      end
    end
  end
end

SizeGroupsDemo.new.build.run
