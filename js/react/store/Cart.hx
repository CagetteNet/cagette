package react.store;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

typedef CartProps = {
  var order:OrderSimple;
  var addToCart:ProductInfo -> Int -> Void;
  var removeFromCart:ProductInfo -> ?Int -> Void;
  var submitOrder:OrderSimple -> Void;
};

class Cart extends react.ReactComponentOfProps<CartProps>
{

  function addToCart(product:ProductInfo, quantity:Int):Void {
    props.addToCart(product, quantity);
  }

  function removeFromCart(product:ProductInfo, quantity:Int):Void {
    props.removeFromCart(product, quantity);
  }

  function removeAllFromCart(product:ProductInfo):Void {
    props.removeFromCart(product);
  }

  function submitOrder():Void {
    props.submitOrder(props.order);
  }

  override public function render(){
    return jsx('
      <div className="cart">
        <h3>Ma Commande</h3>
        ${renderProducts()}    
        ${renderFooter()}
      </div>
    ');
  }

  function renderProducts() {
    var productsToOrder = props.order.products.map(function(product:ProductWithQuantity) {
      var quantity = product.quantity;
      var product = product.product;
      
      return jsx('
        <div className="product-to-order" key=${product.name}>
          <div>${product.name}</div>
          <div>$quantity</div>
          <div className="cart-action-buttons">
            <div onClick=${function(){
              this.addToCart(product, 1);
            }}>
              +
            </div>
            <div onClick=${function(){
              this.removeFromCart(product, 1);
            }}>
              -
            </div>
            <div onClick=${function(){
              this.removeAllFromCart(product);
            }}>
              x
            </div>
          </div>
        </div>
      ');
    });

    return jsx('
      <div className="products-to-order">
        ${productsToOrder}
      </div>
    ');
  }

  function renderFooter() {
    var buttonClasses = ["order-button"];
    var submit = submitOrder;

    if (props.order.products.length == 0) {
      buttonClasses.push("order-button--disabled");
      submit = null;
    }

    return jsx('
      <div className="cart-footer">
        <div className="total">
          Total
          <div>${props.order.total} €</div>
        </div>
        <div className=${buttonClasses.join(" ")} onClick=$submit>Commander</div>
      </div>
    ');
  }
}





