class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :line_id, null: false #必須項目とする

      t.timestamps
    end
  end
end
