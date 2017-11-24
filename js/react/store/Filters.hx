package react.store;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

using Lambda;

typedef FiltersProps = {
  var categories:Array<CategoryInfo>;
  var filters:Array<String>;
  var toggleFilter:String -> Void;
};

class Filters extends react.ReactComponentOfProps<FiltersProps>
{
  override public function render(){
    return jsx('
      <div className="filters">
        <h3>Filtres</h3>
        ${renderFilters()}
      </div>
    ');  
  }

  function renderFilters() {
    return props.categories.map(function(category) {
      var classNames = ["filter"];
      if (props.filters.has(category.name))
        classNames.push("active");

      return jsx('
        <div
          className=${classNames.join(" ")}
          key=${category.id}
          onClick=${function(){
            props.toggleFilter(category.name);
          }}
        >
          ${category.name}
        </div>
      ');
    });
  }
}

