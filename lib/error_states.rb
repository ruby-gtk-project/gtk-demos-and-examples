require 'gtk4'

class ErrorStatesDemo
  MINIMUM_LEVEL = 50

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Error States'
          win.modal = true
          win.resizable = false
          win.titlebar = header_bar
          win.child = grid
        end

        grid.tap do |g|
          g.attach(details_label, 0, 0, 1, 1)
          g.attach(details_entry, 1, 0, 2, 1)
          g.attach(more_details_label, 0, 1, 1, 1)
          g.attach(more_details_entry, 1, 1, 2, 1)
          g.attach(level_label, 0, 2, 1, 1)
          g.attach(level_scale, 1, 2, 2, 1)
          g.attach(mode_label, 0, 3, 1, 1)
          g.attach(mode_switch, 1, 3, 1, 1)
          g.attach(error_label, 2, 3, 1, 1)

          details_entry.tap do |entry|
            entry.signal_connect('notify::text') { validate_more_details(more_details_entry, entry) }
          end

          more_details_entry.tap do |entry|
            entry.signal_connect('notify::text') { validate_more_details(entry, details_entry) }
          end

          level_scale.tap { |scale| scale.signal_connect('value-changed') { level_changed } }

          mode_switch.tap do |sw|
            sw.signal_connect('state-set') { |_, state| mode_requested(state) }
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.error_states', :default_flags)
  def window = @window ||= Gtk::Window.new
  def header_bar = @header_bar ||= Gtk::HeaderBar.new
  def details_entry = @details_entry ||= baseline_entry
  def more_details_entry = @more_details_entry ||= baseline_entry
  def details_label = @details_label ||= field_label('_Details', details_entry)
  def more_details_label = @more_details_label ||= field_label('More D_etails', more_details_entry)
  def level_label = @level_label ||= field_label('_Level', level_scale)
  def mode_label = @mode_label ||= field_label('_Mode', mode_switch)

  def grid
    @grid ||= Gtk::Grid.new.tap do |g|
      g.row_spacing = 10
      g.column_spacing = 10
      g.margin_start = 20
      g.margin_end = 20
      g.margin_top = 20
      g.margin_bottom = 20
    end
  end

  def level_scale
    @level_scale ||= Gtk::Scale.new(:horizontal, Gtk::Adjustment.new(50, 0, 100, 1, 10, 0)).tap do |scale|
      scale.valign = :baseline_fill
      scale.draw_value = false
    end
  end

  def mode_switch
    @mode_switch ||= Gtk::Switch.new.tap do |sw|
      sw.halign = :start
      sw.valign = :baseline_fill
    end
  end

  def error_label
    @error_label ||= Gtk::Label.new('Level too low').tap do |label|
      label.visible = false
      label.halign = :start
      label.valign = :baseline_fill
      label.add_css_class('error')
    end
  end

  private

  def baseline_entry = Gtk::Entry.new.tap { |entry| entry.valign = :baseline_fill }

  def field_label(text, mnemonic_for)
    Gtk::Label.new(text).tap do |label|
      label.halign = :end
      label.valign = :baseline_fill
      label.use_underline = true
      label.mnemonic_widget = mnemonic_for
      label.add_css_class('dim-label')
    end
  end

  # An entry is in error when it has content but its companion does not.
  def validate_more_details(entry, companion)
    if !entry.text.empty? && companion.text.empty?
      entry.tooltip_text = 'Must have details first'
      entry.add_css_class('error')
    else
      entry.tooltip_text = ''
      entry.remove_css_class('error')
    end
  end

  # Turning the switch on only succeeds once the level is high enough; until
  # then the switch stays visually on but its state stays off.
  def mode_requested(state)
    (!state || level_scale.value > MINIMUM_LEVEL).then do |allowed|
      error_label.visible = !allowed
      mode_switch.state = state if allowed
      true
    end
  end

  def level_changed
    if mode_switch.active? && !mode_switch.state? && level_scale.value > MINIMUM_LEVEL
      error_label.visible = false
      mode_switch.state = true
    elsif mode_switch.state? && level_scale.value <= MINIMUM_LEVEL
      mode_switch.state = false
    end
  end
end

ErrorStatesDemo.new.build.run
