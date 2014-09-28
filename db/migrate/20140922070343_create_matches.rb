class CreateMatches < ActiveRecord::Migration
  def change
    create_table :matches do |t|
      t.string :tinder_id

      t.timestamps
    end
  end
end
