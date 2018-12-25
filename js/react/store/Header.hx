package react.store;
// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import react.ReactComponent;
import react.ReactMacro.jsx;
import mui.CagetteTheme.CGColors;
import mui.core.Grid;
import mui.core.TextField;
import mui.core.FormControl;
import mui.core.form.FormControlVariant;
import mui.core.input.InputType;
import mui.core.styles.Classes;
import mui.core.styles.Styles;

import Common;

using Lambda;

typedef HeaderProps = {
	> PublicProps,
	var classes:TClasses;
};

private typedef PublicProps = {
	var submitOrder:OrderSimple->Void;
    var place:PlaceInfos;
	var orderByEndDates:Array<OrderByEndDate>;
}

private typedef TClasses = Classes<[
    cagWrap,
    searchField,
    cagFormContainer,
    cartContainer,
]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class Header extends react.ReactComponentOfProps<HeaderProps> {
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
           cagWrap: {
				maxWidth: 1240,
                margin : "auto",
                padding: "0 10px",
                display: "flex",
                alignItems: Center,
                justifyContent: Center,
			},
            searchField : {
                padding: '0.5em',
            },
            cagFormContainer : {
                fontSize: "1.2rem",
                fontWeight: "bold",//TODO use enum from externs when available
                display: "flex",
                alignItems: Center,
                justifyContent: Center,
                height: 70,
            },
            cartContainer : {
                display: "flex",
                alignItems: Center,
                justifyContent: Center,
                height: 70,
            },
		}
	}

	public function new(props) {
		super(props);
	}

	override public function render() {
        var classes = props.classes;
        
		return jsx('
            <Grid container spacing={8} className=${classes.cagWrap}>
                <Grid item xs={6}> 
                    <DistributionDetails displayLinks={true} orderByEndDates=${props.orderByEndDates} place=${props.place} />
                </Grid>
                <Grid item  xs={3} className=${classes.cagFormContainer}>
                  
                        <TextField                            
                            label="Recherche"
                            variant=${Outlined}
                            type=${Search}  
                            className=${classes.searchField}
                        />                        
                                                                   
                </Grid>
                <Grid item xs={3} className=${classes.cartContainer}>
              
                    <Cart submitOrder=${props.submitOrder} orderByEndDates=${props.orderByEndDates} place=${props.place} />
               
                </Grid>
            </Grid>
        ');
    }
}

