require 'gtk4'

class EditableCellsDemo
  COLUMN_NUMBER = 0
  COLUMN_PRODUCT = 1
  COLUMN_YUMMY = 2

  ITEMS = [
    [3, 'bottles of coke', 20],
    [5, 'packages of noodles', 50],
    [2, 'packages of chocolate chip cookies', 90],
    [1, 'can vanilla ice cream', 60],
    [6, 'eggs', 10]
  ].freeze

  NEW_ITEM = [0, 'Description here', 50].freeze
  NUMBERS = (0..9).map(&:to_s).freeze
  SEPARATOR_ROW = 5

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Editable Cells'
          win.set_default_size(320, 200)
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(title_label)
          box.append(scrolled_window)
          box.append(button_box)

          scrolled_window.tap { |sw| sw.child = tree_view }

          tree_view.tap { |view| add_columns(view) }

          button_box.tap do |buttons|
            buttons.append(add_button)
            buttons.append(remove_button)

            add_button.tap { |btn| btn.signal_connect('clicked') { add_item } }
            remove_button.tap { |btn| btn.signal_connect('clicked') { remove_item } }
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.editable_cells', :default_flags)
  def window = @window ||= Gtk::Window.new
  def title_label = @title_label ||= Gtk::Label.new('Shopping list (you can edit the cells!)')
  def add_button = @add_button ||= Gtk::Button.new(label: 'Add item')
  def remove_button = @remove_button ||= Gtk::Button.new(label: 'Remove item')

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 5).tap do |box|
      box.margin_start = 5
      box.margin_end = 5
      box.margin_top = 5
      box.margin_bottom = 5
    end
  end

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.has_frame = true
      sw.set_policy(:automatic, :automatic)
    end
  end

  def button_box
    @button_box ||= Gtk::Box.new(:horizontal, 4).tap { |box| box.homogeneous = true }
  end

  def items_model
    @items_model ||= Gtk::ListStore.new(Integer, String, Integer).tap do |store|
      ITEMS.each { |item| fill(store.append, item) }
    end
  end

  def numbers_model
    @numbers_model ||= Gtk::ListStore.new(String).tap do |store|
      NUMBERS.each { |number| store.append[0] = number }
    end
  end

  def tree_view
    @tree_view ||= Gtk::TreeView.new(items_model).tap do |view|
      view.vexpand = true
      view.selection.mode = :single
    end
  end

  private

  def fill(row, (number, product, yummy))
    row[COLUMN_NUMBER] = number
    row[COLUMN_PRODUCT] = product
    row[COLUMN_YUMMY] = yummy
  end

  def add_columns(view)
    add_number_column(view)
    add_product_column(view)

    Gtk::TreeViewColumn.new('Yummy', Gtk::CellRendererProgress.new, value: COLUMN_YUMMY).tap do |column|
      view.append_column(column)
    end
  end

  # A combo cell that offers the digits 0-9, with a separator part-way down
  # to show off GtkComboBox's row separator function.
  def add_number_column(view)
    Gtk::CellRendererCombo.new.tap do |renderer|
      renderer.model = numbers_model
      renderer.text_column = 0
      renderer.has_entry = false
      renderer.editable = true

      renderer.signal_connect('edited') do |_, path, text|
        items_model.get_iter(Gtk::TreePath.new(path))[COLUMN_NUMBER] = text.to_i
      end

      renderer.signal_connect('editing-started') do |_, editable, _path|
        editable.set_row_separator_func { |_, iter| iter.path.indices.first == SEPARATOR_ROW }
      end

      Gtk::TreeViewColumn.new('Number', renderer, text: COLUMN_NUMBER).tap do |column|
        view.append_column(column)
      end
    end
  end

  def add_product_column(view)
    Gtk::CellRendererText.new.tap do |renderer|
      renderer.editable = true

      renderer.signal_connect('edited') do |_, path, text|
        items_model.get_iter(Gtk::TreePath.new(path))[COLUMN_PRODUCT] = text
      end

      Gtk::TreeViewColumn.new('Product', renderer, text: COLUMN_PRODUCT).tap do |column|
        view.append_column(column)
      end
    end
  end

  # Inserts below the cursor row, then moves the cursor onto the new row.
  def add_item
    tree_view.cursor.first.then do |path|
      if path
        items_model.insert_after(items_model.get_iter(path))
      else
        items_model.append
      end
    end.tap do |row|
      fill(row, NEW_ITEM)
      tree_view.set_cursor(row.path, tree_view.get_column(0), false)
    end
  end

  def remove_item
    tree_view.selection.selected.then { |row| items_model.remove(row) if row }
  end
end

EditableCellsDemo.new.build.run
