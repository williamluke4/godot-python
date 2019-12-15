{# `render_target` must be defined by calling context #}
{% set py_type = render_target_to_py_type(render_target) %}
{% set gd_type = py_to_gd_type(py_type) %}

{# Define rendering macros #}

{% macro render_method(pyname, return_type=None, args=(), gdname=None, gdapi="") %}
{% set gdname = gdname or pyname %}
{% set return_type = cook_return_type(return_type) %}
{% set args = cook_args(args) %}
def {{ pyname }}({{ py_type }} self{%- if args -%},{%- endif -%}
{%- for arg in args %}
 {{ arg["py_type"] }} {{ arg["name"] }}
{%- if not arg["is_base_type"] %}
 not None
{%- endif -%}
,
{%- endfor -%}
) -> {{ return_type["signature_type"] }}:
{% if return_type["is_builtin"] %}
    cdef {{ return_type["py_type"] }} __ret = {{ return_type["py_type"] }}.__new__({{ return_type["py_type"] }})
    __ret._gd_data = (
{%- elif return_type["is_object"] %}
    cdef {{ return_type["py_type"] }} __ret = {{ return_type["py_type"] }}.__new__({{ return_type["py_type"] }})
    __ret._gd_ptr = (
{%- elif not return_type["is_void"] %}
    return (
{%- else %}
    (
{%- endif %}
gdapi{{ gdapi }}.{{ gd_type }}_{{ gdname }}(&self._gd_data,
{%- for arg in args %}
{%- if arg["is_builtin"] %}
{%- if arg["is_ptr"] %}
 &{{ arg["name"] }}._gd_data,
{%- else %}
 {{ arg["name"] }}._gd_data,
{%- endif %}
{%- elif arg["is_object"] %}
 {{ arg["name"] }}._gd_ptr,
{%- else %}
 {{ arg["name"] }},
{%- endif %}
{% endfor %}
))
{% if return_type["is_builtin"] or return_type["is_object"] %}
    return __ret
{% endif %}
{% endmacro %}

{% macro render_operator_eq() %}
def __eq__({{ py_type }} self, other):
    try:
        return gdapi.{{ gd_type }}_operator_equal(&self._gd_data, &(<{{ py_type }}?>other)._gd_data)
    except TypeError:
        return False
{% endmacro %}

{% macro render_operator_ne() %}
def __ne__({{ py_type }} self, other):
    try:
        return not gdapi.{{ gd_type }}_operator_equal(&self._gd_data, &(<{{ py_type }}?>other)._gd_data)
    except TypeError:
        return False
{% endmacro %}

{% macro render_operator_lt() %}
def __lt__({{ py_type }} self, other):
    try:
        return not gdapi.{{ gd_type }}_operator_less(&self._gd_data, &(<{{ py_type }}?>other)._gd_data)
    except TypeError:
        return False
{% endmacro %}

{% macro render_property(pyname, type, gdname_getter, gdname_setter=None) %}
@property
{{ render_method(pyname=pyname, gdname=gdname_getter, return_type=type) }}
{% if gdname_setter %}
@{{ pyname }}.setter
{{ render_method(pyname=pyname, gdname=gdname_setter, args=[(type + "*", 'val')]) }}
{% endif %}
{% endmacro %}

{# Overwrite blocks to be ignored #}

{% block pxd_header %}
{% endblock %}
{% block cdef_attributes %}
{% endblock %}

{# Now the template will be generated with the context #}

{% extends render_target_to_template(render_target) %}