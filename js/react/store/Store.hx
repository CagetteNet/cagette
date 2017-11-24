package react.store;
import react.ReactComponent;
import react.ReactMacro.jsx;
import haxe.Json;

using Lambda;

import Common;
import utils.CartUtils;
import utils.HttpUtil;

typedef StoreProps = {
  var place:Int;
  var date:String;
};

typedef StoreState = {
  var place:PlaceInfos;
  var orderByEndDates:Array<OrderByEndDate>;
  var categories:Array<CategoryInfo>;
  var productsBySubcategoryIdMap:Map<Int, Array<ProductInfo>>;
  var order:OrderSimple;
  var filters:Array<String>;
};

class Store extends react.ReactComponentOfPropsAndState<StoreProps, StoreState>
{
  static inline var CATEGORY_URL = '/api/shop/categories';
  static inline var PRODUCT_URL = '/api/shop/products';
  static inline var INIT_URL = '/api/shop/init';
  static inline var VIEW_URL = '/place/view';

  public function new() {
    super();
    state = {
      place: null,
      orderByEndDates: [],
      categories: [],
      filters: [],
      productsBySubcategoryIdMap: new Map(),
      order: {
        products: [],
        total: 0
      }
    };
  }

  override function componentDidMount() {
    var categoriesRequest = HttpUtil.fetch(CATEGORY_URL, GET, {date: props.date, place: props.place}, JSON);
    var initRequest = HttpUtil.fetch(INIT_URL, GET, {date: props.date, place: props.place}, JSON);

    initRequest.then(function(infos:Dynamic) {
      setState({
        place: infos.place,
        orderByEndDates: infos.orderEndDates
      });
    })
    .catchError(function(error) {
      trace("ERROR", error);
    });

    categoriesRequest.then(function(categories:Dynamic) {
      var categories:Array<CategoryInfo> = categories.categories;
      var subCategories = [];

      for (category in categories) {
        subCategories = subCategories.concat(category.subcategories);
      }

      setState({
        categories: categories,
        filters: categories.map(function(category) {
          return category.name;
        })
      });

      subCategories.map(function(category:CategoryInfo) {
        return HttpUtil.fetch(PRODUCT_URL, GET, {date: props.date, place: props.place, subcategory: category.id}, JSON)
        .then(function(result) {
          var productsBySubcategoryIdMapCopy = [
            for (key in state.productsBySubcategoryIdMap.keys())
              key => state.productsBySubcategoryIdMap.get(key)
          ];
          productsBySubcategoryIdMapCopy.set(category.id, result.products);

          setState({
            productsBySubcategoryIdMap: productsBySubcategoryIdMapCopy
          });
        });
      });
    })
    .catchError(function(error) {
      trace("ERROR", error);
    });
  }

  function toggleFilter(category:String) {
    var filters = state.filters.copy();

    if (state.filters.find(function(categoryInFilter) {
      return category == categoryInFilter;
    }) != null)
      filters.remove(category);
    else
      filters.push(category);

    if (filters.length == 0)
      filters = state.categories.map(function(category) {
        return category.name;
      });

    setState({
      filters: filters
    });
  }

  function addToCart(productToAdd:ProductInfo, quantity:Int):Void {
    setState({
      order: CartUtils.addToCart(state.order, productToAdd, quantity)
    });
  }

  function removeFromCart(productToRemove:ProductInfo, ?quantity:Int):Void {
    setState({
      order: CartUtils.removeFromCart(state.order, productToRemove, quantity)
    });
  }

  function submitOrder(order:OrderSimple) {
    var orderInSession = {
      total: order.total,
      products: order.products.map(function(p:ProductWithQuantity){
        return {
          productId: p.product.id,
          quantity: p.quantity
        };
      })
    }
    trace('Order', orderInSession);
  }

  override public function render(){
    return jsx('
      <div className="shop">
        ${renderHeader()}
        <ProductList
          categories=${state.categories}
          productsBySubcategoryIdMap=${state.productsBySubcategoryIdMap}
          filters=${state.filters}
          addToCart=$addToCart
        />
        <Filters
          categories=${state.categories}
          filters=${state.filters}
          toggleFilter=$toggleFilter
        />
        <Cart
          order=${state.order}
          addToCart=$addToCart
          removeFromCart=$removeFromCart
          submitOrder=$submitOrder
        />
      </div>
    ');
  }

  function renderHeader() {
    if (state.orderByEndDates == null || state.orderByEndDates.length == 0)
      return null;

    var endDates;

    if (state.orderByEndDates.length == 1) {
      var orderEndDate = state.orderByEndDates[0].date;
      endDates = [jsx('<div key=$orderEndDate>La commande fermera le $orderEndDate</div>')];
    }
    else {
      endDates = state.orderByEndDates.map(function(order) {
        if (order.contracts.length == 1)
          return jsx('
            <div key=${order.date}>
              La commande ${order.contracts[0]} fermera le: ${order.date} 
            </div>
          ');

        return jsx('
          <div key=${order.date}>
            Les autres commandes fermeront: ${order.date} 
          </div>
        ');
      });
    }

    var viewUrl = '$VIEW_URL/${props.place}';
    var addressBlock = Lambda.array([
      state.place.address1,
      state.place.address2,
      [state.place.zipCode, state.place.city].join(" "),
    ].mapi(function(index, element) {
      if (element == null)
        return null;
      return jsx('<div className="address" key=$index>$element</div>');
    }));

    return jsx('
      <div className="shop-header">
        <div>
          <div className="shop-distribution">
            Distribution le ${props.date}
          </div>
          
          <div className="shop-order-ends">
            $endDates
          </div>
        </div>  
        <div className="shop-place">
          <span className="info">
            <span className="glyphicon glyphicon-map-marker"></span>
            <a href=$viewUrl>${state.place.name}</a>
          </span>
          <div>
            $addressBlock
          </div>
        </div>
      </div>
    ');
  }
}

