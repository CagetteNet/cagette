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

typedef CategoryProps = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
	var category:CategoryInfo;
	var active:Bool;
	var onClick:Void->Void;
}

private typedef TClasses = Classes<[cagCategoryActive,]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class Category extends react.ReactComponentOfProps<CategoryProps> {
	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			cagCategoryActive: {
				backgroundColor: CGColors.Bg3,
			},
		}
	}

	public function new(props) {
		super(props);
	}

	override public function render() {
		var classes = props.classes;

		var CategoryContainerClasses = classNames({
			'cagCategoryContainer': true,
			'${classes.cagCategoryActive}': props.active,
		});
		
		return jsx('
            <Grid item xs >
                <div className=${CategoryContainerClasses} onClick=${props.onClick}>
                    <div>
                        <img src=${props.category.image} alt=${props.category.name} />
                        ${props.category.name}
                    </div>
                </div>
            </Grid>
        ');
	}
}