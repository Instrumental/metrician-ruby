class User < ActiveRecord::Base

end


class Recipe < ActiveRecord::Base

  validates_presence_of :name

  has_many :ingredients, :class_name => 'Recipe::Ingredient', :inverse_of => :recipe
  belongs_to :category, :class_name => 'Recipe::Category', :inverse_of => :recipes

end


class Recipe::Category < ActiveRecord::Base

  self.table_name = 'recipe_categories'

  validates_presence_of :name

  has_many :recipes, :inverse_of => :category

end


class Recipe::Ingredient < ActiveRecord::Base

  self.table_name = 'recipe_ingredients'

  validates_presence_of :name

  belongs_to :recipe, :inverse_of => :ingredients

end
