package service;
import Common;
import tink.core.Error;
using tools.DateTool;
using Lambda;

enum SubscriptionServiceError {
	NoSubscription;
	PastDistributionsWithoutOrders;
	PastOrders;
}

/**
 * Subscription service
 * @author web-wizard
 */
class SubscriptionService
{

	public static function getSubscriptionDistributions( subscription : db.Subscription ) : List<db.Distribution> {

		return db.Distribution.manager.search( $catalog == subscription.catalog && $date >= subscription.startDate && $end <= subscription.endDate );
	}

	public static function getSubscriptionNbDistributions( subscription : db.Subscription ) : Int {

		return db.Distribution.manager.count( $catalog == subscription.catalog && $date >= subscription.startDate && $date <= subscription.endDate );
	}

	public static function getSubscriptionTotalPrice( subscription : db.Subscription ) : Float {

		var orders = db.UserOrder.manager.search( $subscription == subscription );
		var totalPrice = 0.0;
		for ( order in orders ) {

			totalPrice += order.quantity * order.productPrice;
		}
		return Formatting.roundTo( totalPrice, 2 );
	}

	public static function getSubscriptionAllOrders( subscription : db.Subscription ) : List<db.UserOrder> {

		return db.UserOrder.manager.search( $subscription == subscription );
	}

	public static function getSubscriptionOrders( subscription : db.Subscription ) : Array<db.UserOrder> {

		var oneDistrib = db.Distribution.manager.search( $catalog == subscription.catalog && $date >= subscription.startDate && $date <= subscription.endDate ).first();
		return Lambda.array( db.UserOrder.manager.search( $subscription == subscription && $distribution == oneDistrib ) );
	}

	public static function isSubscriptionPaid( subscription : db.Subscription ) : Bool {

		var orders = db.UserOrder.manager.search( $subscription == subscription );
		for ( order in orders ) {

			if ( !order.paid ) {

				return false;
			}
			
		}

		return true;

	}

	public static function getDescription( subscription : db.Subscription ) {

		var subscriptionOrders = getSubscriptionOrders( subscription );
		if( subscriptionOrders.length == 0 )  return null;
		var label : String = '';
		for ( order in subscriptionOrders ) {

			label += tools.FloatTool.clean( order.quantity ) + " x " + order.product.name + "<br />";
		}

		return label;
	}

	/**
	 * Checks if dates are correct and if there is no other subscription for this user in that same time range
	 * @param subscription
	 */
	public static function isSubscriptionValid( subscription : db.Subscription, ?previousStartDate : Date, ?previousEndDate : Date  ) : Bool {

		var view = App.current.view;
	
		if ( subscription.startDate == null || subscription.endDate == null ) {

			throw new Error( 'Cette souscription a des dates de début et de fin non définies.' );
		}
		var catalogStartDate = new Date( subscription.catalog.startDate.getFullYear(), subscription.catalog.startDate.getMonth(), subscription.catalog.startDate.getDate(), 0, 0, 0 );
		var catalogEndDate = new Date( subscription.catalog.endDate.getFullYear(), subscription.catalog.endDate.getMonth(), subscription.catalog.endDate.getDate(), 23, 59, 59 );
		if ( subscription.startDate.getTime() < catalogStartDate.getTime() || subscription.startDate.getTime() >= catalogEndDate.getTime() ) {

			throw new Error( 'La date de début de la souscription doit être comprise entre les dates de début et de fin du catalogue.' );
		}
		if ( subscription.endDate.getTime() <= catalogStartDate.getTime() || subscription.endDate.getTime() > catalogEndDate.getTime() ) {

			throw new Error( 'La date de fin de la souscription doit être comprise entre les dates de début et de fin du catalogue.' );
		}

		if ( subscription.id != null && hasPastDistribOrdersOutsideSubscription( subscription ) ) {

			throw TypedError.typed( 'La nouvelle période sélectionnée exclue des commandes déjà passées, Il faut élargir la période sélectionnée.', PastOrders );
		}

		if ( hasPastDistribsWithoutOrders( subscription ) ) {

			throw TypedError.typed( 'La nouvelle période sélectionnée inclue des distributions déjà passées sans commande, Il faut choisir une date ultérieure.', PastDistributionsWithoutOrders );
		}
		
		var subscriptions1;
		var subscriptions2;	
		var subscriptions3;	
		//We are checking that there is no existing subscription with an overlapping time frame for the same user and catalog
		if ( subscription.id == null ) { //We need to check there the id as $id != null doesn't work in the manager.search

			//Looking for existing subscriptions with a time range overlapping the start of the about to be created subscription
			subscriptions1 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog 
															 && $startDate <= subscription.startDate && $endDate >= subscription.startDate, false );
			//Looking for existing subscriptions with a time range overlapping the end of the about to be created subscription
			subscriptions2 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog
															 && $startDate <= subscription.endDate && $endDate >= subscription.endDate, false );	
			//Looking for existing subscriptions with a time range included in the time range of the about to be created subscription		
			subscriptions3 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog
															 && $startDate >= subscription.startDate && $endDate <= subscription.endDate, false );	
		}
		else {

			//Looking for existing subscriptions with a time range overlapping the start of the about to be created subscription
			subscriptions1 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id
															 && $startDate <= subscription.startDate && $endDate >= subscription.startDate, false );
			//Looking for existing subscriptions with a time range overlapping the end of the about to be created subscription
			subscriptions2 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id
															 && $startDate <= subscription.endDate && $endDate >= subscription.endDate, false );	
			//Looking for existing subscriptions with a time range included in the time range of the about to be created subscription		
			subscriptions3 = db.Subscription.manager.search( $user == subscription.user && $catalog == subscription.catalog && $id != subscription.id
															 && $startDate >= subscription.startDate && $endDate <= subscription.endDate, false );	
		}
			
		if ( subscriptions1.length != 0 || subscriptions2.length != 0 || subscriptions3.length != 0 ) {

			throw new Error( 'Il y a déjà une souscription pour ce membre pendant la période choisie.' );
		}
 
		return true;

	}

	 /**
	  *  Creates a new subscription and prevents subscription overlapping and other checks
	  *  @return db.Subscription
	  */
	 public static function createSubscription( user : db.User, catalog : db.Catalog, startDate : Date, endDate : Date ) : db.Subscription {

		var subscription = new db.Subscription();
		subscription.user = user;
		subscription.catalog = catalog;
		subscription.startDate = new Date( startDate.getFullYear(), startDate.getMonth(), startDate.getDate(), 0, 0, 0 );
		subscription.endDate = new Date( endDate.getFullYear(), endDate.getMonth(), endDate.getDate(), 23, 59, 59 );

		if ( isSubscriptionValid( subscription ) ) {

			subscription.insert();
		}

		return subscription;

	}


	 public static function updateSubscription( subscription : db.Subscription, startDate : Date, endDate : Date ) {

		
	
		subscription.lock();
		subscription.startDate = new Date( startDate.getFullYear(), startDate.getMonth(), startDate.getDate(), 0, 0, 0 );
		subscription.endDate = new Date( endDate.getFullYear(), endDate.getMonth(), endDate.getDate(), 23, 59, 59 );
		var ordersData = new Array< { id : Int, productId : Int, qt : Float, paid : Bool, invertSharedOrder : Bool, userId2 : Int } >();
		var subscriptionOrders = getSubscriptionOrders( subscription );
		for ( order in subscriptionOrders ) {

			ordersData.push( { id : null, productId : order.product.id, qt : order.quantity, paid : false, invertSharedOrder : false, userId2 : null } );
			
		}
		if ( isSubscriptionValid( subscription ) ) {

			subscription.update();
			SubscriptionService.createCSARecurrentOrders( subscription, ordersData );
		}

	}

	 /**
	  *  Deletes a subscription if there is no orders that occurred in the past
	  *  @return db.Subscription
	  */
	 public static function deleteSubscription( subscription : db.Subscription ) {

		if ( hasPastDistribOrders( subscription ) ) {

			throw TypedError.typed( 'Impossible de supprimer cette souscription car il y a des commandes pour des distributions passées.', PastOrders );
		}

		//Delete all the orders for this subscription
		var subscriptionOrders = db.UserOrder.manager.search( $subscription == subscription, false );
		for ( order in subscriptionOrders ) {

			order.lock();
			order.delete();
		}
		//Delete the subscription
		subscription.lock();
		subscription.delete();

	}

	/**
	 *  Checks whether there are orders with non zero quantity in the past
	 *  @param d - 
	 *  @return Bool
	 */
	public static function hasPastDistribOrders( subscription : db.Subscription ) : Bool {

		if ( !hasPastDistributions( subscription ) ) {

			return false;
		}
		else {

			var now = Date.now();
			var endOfToday = new Date( now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59 );
			var pastDistributions : List<db.Distribution> = db.Distribution.manager.search( $catalog == subscription.catalog  && $date <= endOfToday && $date >= subscription.startDate && $date <= subscription.endDate );
			for ( distribution in pastDistributions ) {

				if ( db.UserOrder.manager.count( $distribution == distribution && $subscription == subscription ) != 0 ) {
					
					return true;
				}

			}
		}
		
		return false;
		
	}


	public static function hasPastDistribOrdersOutsideSubscription( subscription : db.Subscription ) : Bool {

		var now = Date.now();
		var endOfToday = new Date( now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59 );
		var orders =  db.UserOrder.manager.search( $subscription == subscription ).array();
		for ( order in orders ) {

			if ( order.distribution != null && order.distribution.date.getTime() <= endOfToday.getTime() && ( order.distribution.date.getTime() < subscription.startDate.getTime() || order.distribution.date.getTime() > subscription.endDate.getTime() ) ) {

				return true;
			}
		}
		
		return false;
		
	}

	public static function hasPastDistribsWithoutOrders( subscription : db.Subscription ) : Bool {

		if ( !hasPastDistributions( subscription ) ) {

			return false;
		}
		else {

			var now = Date.now();
			var endOfToday = new Date( now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59 );
			var pastDistributions : List<db.Distribution> = db.Distribution.manager.search( $catalog == subscription.catalog  && $date <= endOfToday && $date >= subscription.startDate && $date <= subscription.endDate );
			for ( distribution in pastDistributions ) {

				if ( db.UserOrder.manager.count( $distribution == distribution && $subscription == subscription ) == 0 ) {
					
					return true;
				}

			}
		}
		
		return false;
	}

	
	public static function hasPastDistributions( subscription : db.Subscription ) : Bool {

		//Check if there are distributions in the past for this subscription
		var now = Date.now();
		var endOfToday = new Date( now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59 );
		return db.Distribution.manager.count( $catalog == subscription.catalog  && $date <= endOfToday && $date >= subscription.startDate && $date <= subscription.endDate ) != 0;
	}


	public static function createCSARecurrentOrders( subscription : db.Subscription,
		ordersData : Array< { id : Int, productId : Int, qt : Float, paid : Bool, invertSharedOrder : Bool, userId2 : Int } > ) : Array<db.UserOrder> {

		if ( subscription == null ) {
			
			throw new Error( "Il n\'y a pas de souscription à ce nom. Il faut d\'abord créer une souscription pour cette personne pour pouvoir ajouter des commandes."  );
		}

		var subscriptionAllOrders = getSubscriptionAllOrders( subscription );
		for ( order in subscriptionAllOrders ) {

			order.lock();
			order.delete();
		}

		var subscriptionDistributions = getSubscriptionDistributions( subscription );

		var t = sugoi.i18n.Locale.texts;
	
		var orders : Array<db.UserOrder> = [];
		for ( distribution in subscriptionDistributions ) {

			for ( order in ordersData ) {

				var product = db.Product.manager.get( order.productId, false );
				// User2 + Invert
				var user2 : db.User = null;
				var invert = false;
				if ( order.userId2 != null && order.userId2 != 0 ) {

					user2 = db.User.manager.get( order.userId2, false );
					if ( user2 == null ) throw new Error( t._( "Unable to find user #::num::", { num : order.userId2 } ) );
					if ( !user2.isMemberOf( product.catalog.group ) ) throw new Error( t._( "::user:: is not part of this group", { user : user2 } ) );
					if ( subscription.user.id == user2.id ) throw new Error( t._( "Both selected accounts must be different ones" ) );
					
					invert = order.invertSharedOrder;
				}
				

				var newOrder =  OrderService.make( subscription.user, order.qt , product,  distribution.id, order.paid , user2, invert, subscription );
				if ( newOrder != null ) orders.push( newOrder );

			}
		}

		return orders;
		
	}


}