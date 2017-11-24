package utils;

import Math;
using Lambda;

import Common;

class CartUtils {
  public static function addToCart(order:OrderSimple, productToAdd:ProductInfo, quantity:Int):OrderSimple {
    var products = order.products.copy();
    var total = order.total;

    var existingProduct = products.find(function(p) {
      return p.product.id == productToAdd.id;
    });

    if (existingProduct == null)
      products.push({
        product: productToAdd,
        quantity: quantity
      });
    else
      existingProduct.quantity += quantity;

    total += quantity * productToAdd.price;
    total = Math.round(total * 100) / 100; // to avoid calculation errors

    return {
      products: products,
      total: total
    };
  }

  public static function removeFromCart(order:OrderSimple, productToRemove:ProductInfo, ?quantity:Int):OrderSimple {
    var products = order.products.copy();
    var total = order.total;

    var existingProduct = products.find(function(p) {
      return p.product.id == productToRemove.id;
    });

    if (quantity == null)
      quantity = existingProduct.quantity;

    if (existingProduct == null)
      throw "Can't remove a non existing product";
    else if (quantity >= existingProduct.quantity)
      products.remove(existingProduct)
    else
      existingProduct.quantity -= quantity;

    if (products.length == 0)
      total = 0;
    else {
      total -= Math.min(quantity, existingProduct.quantity) * productToRemove.price;
      total = Math.round(total * 100) / 100; // to avoid calculation errors
    }

    return {
      products: products,
      total: total
    };
  }
}
