package react.ubo.components;

import react.ReactMacro.jsx;
import react.ReactComponent;
import mui.Color;
import mui.core.*;
import mui.core.form.FormControlMargin;
import mui.core.grid.GridSpacing;
import mui.core.button.ButtonVariant;
import react.mui.pickers.MuiPickersUtilsProvider;
import dateFns.DateFnsLocale;
import dateFns.FrDateFnsUtils;
import react.mui.Box;
import react.mui.Alert;
import react.formik.Formik;
import react.formik.Form;
import react.formikMUI.TextField;
import react.formikMUI.DatePicker;
import react.formikMUI.Select;
import react.ubo.vo.UboVO;
import react.ubo.Utils;

import react.ubo.vo.UboVO;

private typedef Props = {
    ?declarationId: Int,
    ?ubo: UboVO,
    canEdit: Bool,
    countrys: Array<{alpha2: String, nationality: String, country: String}>,
    ?onSubmit: (?uboId: Int, data: js.html.FormData, formikBag: Dynamic) -> Void,
    ?onSubmitSuccess: () -> Void,
    ?onSubmitFailure: () -> Void,
};

typedef FormProps = {
    FirstName: String,
    LastName: String,
    Address: {
        AddressLine1: String,
        ?AddressLine2: String,
        City: String,
        PostalCode: String,
        Country: String,
        ?Region: String,
    },
    Nationality: String,
    Birthday: Date,
    Birthplace: {
        City: String,
        Country: String
    }
};

class UboForm extends ReactComponentOfProps<Props> {

    private var initialValues: FormProps;

    public function new(props: Props) {
        super(props);

        var ubo = props.ubo;
        this.initialValues = {
            FirstName: ubo == null ? "" : ubo.FirstName,
            LastName: ubo == null ? "" : ubo.LastName,
            Address: {
                AddressLine1: ubo == null ? "" : ubo.Address.AddressLine1,
                AddressLine2: ubo == null ? "" : (ubo.Address.AddressLine2 != null ? ubo.Address.AddressLine2 : ""),
                City: ubo == null ? "" : ubo.Address.City,
                Region: ubo == null ? "" : (ubo.Address.Region != null ? ubo.Address.Region : ""),
                PostalCode: ubo == null ? "" : ubo.Address.PostalCode,
                Country: ubo == null ? "FR" : ubo.Address.Country,
            },
            Nationality: ubo == null ? "FR" : ubo.Nationality,
            Birthday: ubo == null ? Date.now() : Date.fromTime(ubo.Birthday * 1000),
            Birthplace: {
                City: ubo == null ? "" : ubo.Birthplace.City,
                Country: ubo == null ? "FR" : ubo.Birthplace.Country,
            }
        };
    }

    override public function render() {
        var ubo = props.ubo;

        var res = 
            <MuiPickersUtilsProvider utils={FrDateFnsUtils} locale=${DateFnsLocale.fr} >
                <Formik initialValues=$initialValues onSubmit=$onSubmit>
                    {formikProps -> (
                        <Form>
                            {renderStatus(formikProps.status)}

                            {renderTwoColumns(
                                renderTextField(formikProps, "FirstName", "Prénom"),
                                renderTextField(formikProps, "LastName", "Nom")
                            )}
                           
                            {renderTextField(formikProps, "Address.AddressLine1", "Adresse")}
                            {renderTextField(formikProps, "Address.AddressLine2", "Adresse 2", false)}

                            {renderTwoColumns(
                                renderTextField(formikProps, "Address.City", "Ville"),
                                renderTextField(formikProps, "Address.PostalCode", "Code postal")
                            )}
                            
                            {renderTwoColumns(
                                renderCountryField(formikProps, "Address.Country", "Pays", "country"),
                                renderRegionField(formikProps)
                            )}
                            
                            {renderTwoColumns(
                                renderCountryField(formikProps, "Nationality", "Nationalité", "nationality"),
                                <FormControl fullWidth margin={FormControlMargin.Dense}>
                                    <DatePicker
                                        InputProps={{
                                            style: { textTransform: css.TextTransform.Capitalize }
                                        }}
                                        disabled={!props.canEdit || formikProps.isSubmitting}
                                        required 
                                        cancelLabel="Annuler"
                                        format="d MMMM yyyy"
                                        name="Birthday"
                                        label="Date de naissance"
                                    />
                                </FormControl>
                            )}

                            {renderTwoColumns(
                                renderTextField(formikProps, "Birthplace.City", "Ville de naissance"),
                                renderCountryField(formikProps, "Birthplace.Country", "Pays de naissance", "country")
                            )}
                            
                            {renderButton(formikProps.isSubmitting)}
                        </Form>
                    )}
                </Formik>
            </MuiPickersUtilsProvider>
        ;

        return jsx('$res');
    }

    /**
     * 
     */
     private function renderStatus(?status: Dynamic) {
        if (status == null) return null;
        return 
            <Box p={2}>
                <Alert severity="error">{status}</Alert>
            </Box>
        ;
    }

    private function renderTwoColumns(childLeft: Dynamic, ?childRight: Dynamic) {
        var colSize = 12;
        var right = <></>;
        if (childRight != null) {
            colSize = 6;
            right = <Grid item xs={colSize}>{childRight}</Grid>;
        }
        return  
            <Grid container spacing=${GridSpacing.Spacing_4}>
                <Grid item xs={colSize}>
                    {childLeft}
                </Grid>
                {right}
            </Grid>
        ;
     }
    
    private function renderTextField(formikProps: Dynamic, name: String, label: String, required: Bool = true, fullWidth: Bool =true) {
        return  
            <TextField
                margin={mui.core.form.FormControlMarginNoneDense.Dense}
                fullWidth=$fullWidth
                required=$required
                name=$name
                label=$label
                disabled={!props.canEdit || formikProps.isSubmitting}
            />
        ;
    }

    private function renderCountryField(formikProps: Dynamic, name: String, label: String, labelField: String) {
        var id = "ubo-country-" + name;

        return
            <FormControl fullWidth margin=${FormControlMargin.Dense}>
                <InputLabel id=$id>{label}</InputLabel>
                <Select labelId=$id name=$name fullWidth required disabled={!props.canEdit  || formikProps.isSubmitting}>
                    ${props.countrys.map(c -> 
                        <MenuItem key=${c.alpha2} value=${c.alpha2} dense>
                            ${untyped c[labelField]}
                        </MenuItem>
                    )}
                </Select>
            </FormControl>
        ;
    }
    
    private function renderRegionField(formikProps: Dynamic) {
        var countryCode = formikProps.values.Address.Country;
        if (["US", "CA", "MX"].indexOf(countryCode) != -1) {
            return renderTextField(formikProps, "Address.Region", "Région");
        }
        return <></>;
    }

    private function renderButton(isSubmitting: Bool) {
        if (!props.canEdit) return <></>;
        return 
            <Box pt={4} display="flex" justifyContent="center">
                <Button
                    disabled={isSubmitting}
                    variant={ButtonVariant.Contained}
                    color={Color.Primary}
                    type={mui.core.button.ButtonType.Submit}
                    >
                    Valider
                </Button>
            </Box>
        ;
    }
    
    /**
     * 
     */
     private function onSubmit(values: FormProps, formikBag: Dynamic) {
        var data = Utils.addUboFormValuesToFormData(values);
        if (props.onSubmit != null) {
            props.onSubmit(props.ubo != null ? props.ubo.Id : null, data, formikBag);
        }
        // props.postOrPutUbo(
        //     data,
        //     props.declarationId,
        //     props.ubo != null ? props.ubo.Id : null
        // ).then(res -> {
        //     formikBag.setSubmitting(false);
        // }).catchError(err -> {
        //     formikBag.setSubmitting(false);
        //     formikBag.setStatus("Un erreur est survenue");
        // });
    }
}