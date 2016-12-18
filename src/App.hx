import db.User;
import thx.semver.Version;
import Common;
 
class App extends sugoi.BaseApp {

	public static var current : App = null;
	public static var t : sugoi.i18n.translator.ITranslator;
	public static var config = sugoi.BaseApp.config;
	
	public var eventDispatcher :hxevents.Dispatcher<Event>;	
	public var plugins : Array<plugin.IPlugIn>;
	
	/**
	 * Version management
	 * @doc https://github.com/fponticelli/thx.semver
	 */ 
	//public static var VERSION = ([0,9,2]  : Version).withPre("july");
	static var branch = MyMacros.getGitBranch() + MyMacros.getGitCommitDate();
	static var verArray  = branch.split(".").map(Std.parseInt);
	public static var VERSION = ( [verArray[0],verArray[1],verArray[2]] : Version).withPre((verArray[0]==null)? branch: MyMacros.getGitCommitDate());
	
	public static function main() {
		
		App.t = sugoi.form.Form.translator = new sugoi.i18n.translator.TMap(getTranslationArray(), "fr");
		sugoi.BaseApp.main();
	}
	
	/**
	 * Init plugins and event dispatcher just before launching the app
	 */
	override public function mainLoop() {
		eventDispatcher = new hxevents.Dispatcher<Event>();
		plugins = [ new plugin.Tutorial() ];
		#if plugins
		plugins.push( new hosted.HostedPlugIn() );
		plugins.push( new pro.ProPlugIn() );
		plugins.push( new connector.ConnectorPlugIn() );
		#end
		
	
		super.mainLoop();
	}
	
	override function beforeDispatch() {
		
		//send "current page" event
		event( Page(this.uri) );
		
		super.beforeDispatch();
	}
	
	public function getPlugin(name:String):plugin.IPlugIn {
		for (p in plugins) {
			if (p.getName() == name) return p;
		}
		return null;
	}
	
	public static function log(t:Dynamic) {
		if(App.config.DEBUG) {
			neko.Web.logMessage(Std.string(t)); //write in Apache error log
			#if weblog
			Weblog.log(t); //write en Weblog console (https://lib.haxe.org/p/weblog/)
			#end
		}
	}
	
	public function event(e:Event) {
		return this.eventDispatcher.dispatch(e);
	}
	
	/**
	 * pour feeder l'object de traduction des formulaires
	 */
	public static function getTranslationArray() {
	
		var out = new Map<String,String>();
		out.set("firstName", "Prénom");
		out.set("lastName", "Nom");
		out.set("firstName2", "Prénom du conjoint");
		out.set("lastName2", "Nom du conjoint");
		out.set("email2", "e-mail du conjoint");
		out.set("address1", "adresse");
		out.set("address2", "adresse");
		out.set("zipCode", "code postal");
		out.set("city", "commune");
		out.set("phone", "téléphone");
		out.set("phone2", "téléphone du conjoint");
		out.set("select", "sélectionnez");
		out.set("contract", "Contrat");
		out.set("place", "Lieu");
		out.set("name", "Nom");
		out.set("cdate", "Date d'entrée dans le groupe");
		out.set("quantity", "Quantité");
		out.set("paid", "Payé");
		out.set("user2", "(facultatif) partagé avec ");
		out.set("product", "Produit");
		out.set("user", "Adhérent");
		out.set("txtIntro", "Texte de présentation du groupe");
		out.set("txtHome", "Texte en page d'accueil pour les adhérents connectés");
		out.set("txtDistrib", "Texte à faire figurer sur les listes d'émargement lors des distributions");
		out.set("extUrl", "URL du site du groupe.");
		
		out.set("distributor1", "Distributeur 1");
		out.set("distributor2", "Distributeur 2");
		out.set("distributor3", "Distributeur 3");
		out.set("distributor4", "Distributeur 4");
		out.set("distributorNum", "Nbre de distributeurs nécessaires (de 0 à 4)");
		
		out.set("startDate", "Date de début");
		out.set("endDate", "Date de fin");
		
		out.set("orderStartDate", "Date ouverture des commandes");
		out.set("orderEndDate", "Date fermeture des commandes");	
		
		out.set("date", "Date de distribution");	
		out.set("active", "actif");	
		
		out.set("contact", "Reponsable");
		out.set("vendor", "Producteur");
		out.set("text", "Texte");
		out.set("flags", "Options");
		out.set("4h", "Recevoir des notifications par email 4h avant les distributions");
		out.set("HasEmailNotif4h", "Recevoir des notifications par email 4h avant les distributions");
		out.set("24h", "Recevoir des notifications par email 24h avant les distributions");
		out.set("HasEmailNotif24h", "Recevoir des notifications par email 24h avant les distributions");
		out.set("Tuto", "Activer tutoriels");
		out.set("HasMembership", "Gestion des adhésions");
		out.set("DayOfWeek", "Jour de la semaine");
		out.set("Monday", "Lundi");
		out.set("Tuesday", "Mardi");
		out.set("Wednesday", "Mercredi");
		out.set("Thursday", "Jeudi");
		out.set("Friday", "Vendredi");
		out.set("Saturday", "Samedi");
		out.set("Sunday", "Dimanche");
		out.set("cycleType", "Récurrence");
		out.set("Weekly", "hebdomadaire");
		out.set("Monthly", "mensuelle");
		out.set("BiWeekly", "toutes les deux semaines");
		out.set("TriWeekly", "toutes les 3 semaines");
		out.set("price", "prix TTC");
		out.set("uname", "Nom");
		out.set("pname", "Produit");
		out.set("organic", "Agriculture biologique");
		out.set("hasFloatQt", "Autoriser quantités \"à virgule\"");
		
		out.set("membershipRenewalDate", "Adhésions : Date de renouvellement");
		out.set("membershipPrice", "Adhésions : Coût de l'adhésion");
		out.set("UsersCanOrder", "Les adhérents peuvent saisir leur commande en ligne");
		out.set("StockManagement", "Gestion des stocks");
		out.set("contact", "Responsable");
		out.set("PercentageOnOrders", "Ajouter des frais au pourcentage de la commande");
		out.set("percentageValue", "Pourcentage des frais");
		out.set("percentageName", "Libellé pour ces frais");
		out.set("fees", "frais");
		out.set("AmapAdmin", "Administrateur du groupe");
		out.set("Membership", "Accès à la gestion des adhérents");
		out.set("Messages", "Accès à la messagerie");
		out.set("vat", "TVA");
		out.set("desc", "Description");
		out.set("ShopMode", "Mode boutique");
		out.set("IsAmap", "Votre groupe est une AMAP");
		out.set("ComputeMargin", "Appliquer une marge à la place des pourcentages");
		out.set("ShopCategoriesFromTaxonomy", "Catégoriser automatiquement les produits");
		out.set("HidePhone", "Masquer le téléphone du responsable sur la page publique");
		out.set("ref", "Référence");
		out.set("linkText", "Intitulé du lien");
		out.set("linkUrl", "URL du lien");
		
		out.set("regOption", "Inscription de nouveaux adhérents");
		out.set("Closed", "Fermé : Le coordinateur ajoute les nouveaux adhérents");
		out.set("WaitingList", "Liste d'attente");
		out.set("Open", "Ouvert : tout le monde peut s'inscrire");
		out.set("Full", "Complet : Le groupe n'accepte plus de nouveaux adhérents");
		out.set("percent", "Pourcentage");
		out.set("pinned", "Mets en avant les produits");
		out.set("daysBeforeOrderStart", "Ouverture de commande (nbre de jours avant distribution)");
		out.set("daysBeforeOrderEnd", "Fermeture de commande (nbre de jours avant distribution)");
		out.set("CagetteNetwork", "Me lister dans l'annuaire des groupes Cagette.net");
		out.set("unitType", "Unité");
		out.set("qt", "Quantité");
		out.set("Unit", "Pièce");
		out.set("Kilogram", "Kilogrammes");
		out.set("Gram", "Grammes");
		out.set("Litre", "Litres");		
		out.set("htPrice", "Prix H.T");
		return out;
	}
	
	
	public function populateAmapMembers() {		
		return user.amap.getMembersFormElementData();
	}
	
	public static function getMailer() {
		if (config.get("smtp_host") == null) throw "missing SMTP config";
		
		var conf = {
			host:config.get("smtp_host"),
			port:config.getInt("smtp_port"),
			user:config.get("smtp_user"),
			pass:config.get("smtp_pass")
		};
		
		return new ufront.mailer.SmtpMailer(conf);	
	}
	
	public static function quickMail(to:String, subject:String, html:String){
		var e = new ufront.mail.Email();		
		e.setSubject(subject);
		e.to(new ufront.mail.EmailAddress(to));			
		e.from(new ufront.mail.EmailAddress(App.config.get("default_email"),"Cagette Pro"));		
		
		var html = App.current.processTemplate("plugin/pro/mail/message.mtt", {text:html});		
		e.setHtml(html);
		
		current.event(SendEmail(e));
		
		if (!App.config.DEBUG){
			getMailer().send(e);	
		}
		
		
	}
	
	/**
	 * process a template and returns the generated string
	 * @param	tpl
	 * @param	ctx
	 */
	public function processTemplate(tpl:String, ctx:Dynamic):String {
		Reflect.setField(ctx, 'HOST', App.config.HOST);
		
		var tpl = loadTemplate(tpl);
		var html = tpl.execute(ctx);	
		#if php
		if ( html.substr(0, 4) == "null") html = html.substr(4);
		#end
		return html;
	}
	
	
	
}
