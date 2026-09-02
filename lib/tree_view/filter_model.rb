require 'gtk4'

class FilterModelDemo
  WIDTH_COLUMN = 0
  HEIGHT_COLUMN = 1

  RECTANGLES = [[10, 20], [5, 25], [15, 15]].freeze
  NARROW = 10

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Filter Model'
          win.child = grid
        end

        grid.tap do |g|
          g.attach(original_label, 0, 0, 1, 1)
          g.attach(original_view, 0, 1, 1, 1)
          g.attach(computed_label, 1, 0, 1, 1)
          g.attach(computed_view, 1, 1, 1, 1)
          g.attach(filtered_label, 0, 2, 1, 1)
          g.attach(filtered_view, 0, 3, 1, 1)
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.filter_model', :default_flags)
  def window = @window ||= Gtk::Window.new
  def original_label = @original_label ||= section_label('Original')
  def computed_label = @computed_label ||= section_label('Computed Columns')
  def filtered_label = @filtered_label ||= section_label('Filtered')
  def adjustment = @adjustment ||= Gtk::Adjustment.new(5, 5, 50, 1, 5, 0)

  def grid
    @grid ||= Gtk::Grid.new.tap do |g|
      g.margin_start = 10
      g.margin_end = 10
      g.margin_top = 10
      g.margin_bottom = 10
      g.row_spacing = 10
      g.column_spacing = 10
      g.column_homogeneous = true
    end
  end

  def store
    @store ||= Gtk::ListStore.new(Integer, Integer).tap do |s|
      RECTANGLES.each do |width, height|
        s.append.tap do |row|
          row[WIDTH_COLUMN] = width
          row[HEIGHT_COLUMN] = height
        end
      end
    end
  end

  # Only rows narrower than NARROW survive the filter.
  def filtered_model
    @filtered_model ||= Gtk::TreeModelFilter.new(store).tap do |filter|
      filter.set_visible_func { |model, iter| model.get_value(iter, WIDTH_COLUMN) < NARROW }
    end
  end

  def original_view
    @original_view ||= tree_view(store).tap do |view|
      add_spin_column(view, 'Width', WIDTH_COLUMN)
      add_spin_column(view, 'Height', HEIGHT_COLUMN)
    end
  end

  # Area and squareness are not stored anywhere: the cell data functions
  # derive them from width and height every time a cell is drawn.
  #
  # The C demo computes them with gtk_tree_model_filter_set_modify_func
  # instead. That path segfaults in ruby-gnome 4.3.7 as soon as a second
  # view is attached to the same child store, so the columns are computed
  # here rather than in a filter model.
  def computed_view
    @computed_view ||= tree_view(store).tap do |view|
      view.search_column = WIDTH_COLUMN
      add_number_column(view, 'Width') { |width, _| width }
      add_number_column(view, 'Height') { |_, height| height }
      add_number_column(view, 'Area') { |width, height| width * height }
      add_square_column(view)
    end
  end

  def filtered_view
    @filtered_view ||= tree_view(filtered_model).tap do |view|
      view.search_column = WIDTH_COLUMN
      add_number_column(view, 'Width') { |width, _| width }
      add_number_column(view, 'Height') { |_, height| height }
    end
  end

  private

  def section_label(text)
    Gtk::Label.new(text).tap do |l|
      l.xalign = 0
      l.attributes = Pango::AttrList.new.tap { |attrs| attrs.insert(Pango::AttrWeight.new(:bold)) }
    end
  end

  def tree_view(model) = Gtk::TreeView.new(model).tap { |view| view.headers_clickable = false }

  def add_spin_column(view, title, index)
    Gtk::CellRendererSpin.new.tap do |renderer|
      renderer.editable = true
      renderer.adjustment = adjustment
      renderer.signal_connect('edited') do |_, path, text|
        store.get_iter(Gtk::TreePath.new(path))[index] = text.to_i
      end

      Gtk::TreeViewColumn.new(title, renderer, text: index).tap { |column| view.append_column(column) }
    end
  end

  def add_number_column(view, title, &value)
    Gtk::CellRendererText.new.then do |renderer|
      Gtk::TreeViewColumn.new(title, renderer).tap do |column|
        column.set_cell_data_func(renderer) do |_, cell, model, iter|
          cell.text = value.call(model.get_value(iter, WIDTH_COLUMN),
                                 model.get_value(iter, HEIGHT_COLUMN)).to_s
        end

        view.append_column(column)
      end
    end
  end

  def add_square_column(view)
    Gtk::CellRendererPixbuf.new.tap do |renderer|
      renderer.icon_name = 'object-select-symbolic'

      Gtk::TreeViewColumn.new('Square', renderer).tap do |column|
        column.set_cell_data_func(renderer) do |_, cell, model, iter|
          cell.visible = model.get_value(iter, WIDTH_COLUMN) == model.get_value(iter, HEIGHT_COLUMN)
        end

        view.append_column(column)
      end
    end
  end
end

FilterModelDemo.new.build.run
