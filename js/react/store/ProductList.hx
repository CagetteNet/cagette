package react.store;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

using Lambda;

typedef ProductListProps = {
  var categories:Array<CategoryInfo>;
  var productsBySubcategoryIdMap:Map<Int, Array<ProductInfo>>;
  var filters:Array<String>;
  var addToCart:ProductInfo -> Int -> Void;
};

class ProductList extends react.ReactComponentOfProps<ProductListProps>
{
  override public function render(){
    return jsx('
      <div className="categories">
        ${renderCategories()}
      </div>
    ');
  }

  function renderCategories() {
    return props.categories.map(function(category) {
      if (!props.filters.has(category.name))
        return null;

      return jsx('
        <div className="category" key=${category.name}>
          <h2>${category.name}</h2>
          <div className="subCategories">
            ${renderSubCategories(category)}
          </div>
        </div>
      ');
    });
  }

  function renderSubCategories(category) {
    var subCategories = category.subcategories.map(function(category) {
      if (!props.productsBySubcategoryIdMap.exists(category.id))
        return jsx('<div key=${category.name}>Loading...</div>');

      var products = props.productsBySubcategoryIdMap.get(category.id);

      return jsx('
        <div className="sub-category" key=${category.name}>
          <h3>${category.name}</h3>
          <div className="products">
            ${renderProducts(products)}
          </div>
        </div>
      ');
    });

    return jsx('
      <div className="sub-categories">
        $subCategories
      </div>
    ');
  }

  function renderProducts(products) {
    return products.map(function(product) {
      return jsx('
        <Product product=${product} key=${product.id} addToCart=${props.addToCart}/>
      ');
    });
  }
}

