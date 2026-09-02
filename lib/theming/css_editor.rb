require 'gtk4'

# A live CSS editor: a text view whose contents are re-parsed into a
# GtkCssProvider on every keystroke, with parse errors underlined in place.
# The theming demos all share this panel.
class CssEditor
  ASSETS = File.expand_path('../../demos/gtk-demo', __dir__).freeze

  def initialize(css_file)
    @css_file = File.join(ASSETS, css_file)
  end

  def build
    @build ||= scrolled_window.tap do |sw|
      sw.child = text_view

      buffer.tap do |b|
        b.text = css_source
        b.signal_connect('changed') { reload }
      end

      provider.tap do |p|
        p.signal_connect('parsing-error') { |_, section, error| mark_error(section, error) }
      end

      reload

      Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, MAX_PRIORITY)
    end
  end

  MAX_PRIORITY = 0xffffffff

  def scrolled_window = @scrolled_window ||= Gtk::ScrolledWindow.new
  def text_view = @text_view ||= Gtk::TextView.new(buffer)
  def provider = @provider ||= Gtk::CssProvider.new

  def buffer
    @buffer ||= Gtk::TextBuffer.new.tap do |b|
      b.create_tag('warning', 'underline' => :single)
      b.create_tag('error', 'underline' => :error)
    end
  end

  # gresource URLs cannot be resolved outside the C demo's bundle, so point
  # them at the flat asset directory the demos ship instead.
  def css_source
    @css_source ||= File.read(@css_file).gsub(%r{resource://[\w/\-.]*?/([\w\-.]+)}) do
      "file://#{File.join(ASSETS, Regexp.last_match(1))}"
    end
  end

  private

  def reload
    buffer.remove_all_tags(buffer.start_iter, buffer.end_iter)
    provider.load(string: buffer.text)
  end

  def mark_error(section, error)
    buffer.apply_tag_by_name(
      error.is_a?(Gtk::CssParserWarning) ? 'warning' : 'error',
      buffer.get_iter_at(line: section.start_location.lines, index: section.start_location.line_bytes),
      buffer.get_iter_at(line: section.end_location.lines, index: section.end_location.line_bytes)
    )
  end
end
