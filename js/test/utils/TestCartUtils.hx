package test.utils;

import sys.io.File.getContent;
import haxe.Json.parse;
import utest.Assert;
import utils.CartUtils;
import Common;

class TestCartUtils
{
  static var products:Array<ProductInfo>;
  public function new() {
    var http = new haxe.Http("localhost/js/test/mocks.json?format=json");

    products = parse(getContent("js/test/mocks.json")); 
  }

  public function testAddToCart()
  {    
    var order = {
      products: [{
        product: products[0],
        quantity: 1
      }],
      total: products[0].price
    };

    var newProduct = products[1];

    order = CartUtils.addToCart(order, newProduct, 1);
    Assert.equals(order.products.length, 2);
    Assert.equals(order.total, products[0].price + products[1].price);
    order = CartUtils.addToCart(order, newProduct, 3);
    Assert.equals(order.products[1].quantity, 4);
    Assert.equals(order.total, products[0].price + 4 * products[1].price);
  }

  public function testRemoveFromCart()
  {    
    var order = {
      products: [{
        product: products[0],
        quantity: 5
      }, {
        product: products[1],
        quantity: 3
      }],
      total: 5 * products[0].price + 3 * products[1].price
    };

    order = CartUtils.removeFromCart(order, products[0], 2);
    Assert.equals(order.products[0].quantity, 3);
    Assert.equals(order.total, 3 * products[0].price + 3 * products[1].price);
    order = CartUtils.removeFromCart(order, products[1]);
    Assert.equals(order.products.length, 1);
    Assert.equals(order.total, 3 * products[0].price);
  }
}
