{% macro generate_schema_name(custom_schema, node) -%}
    {%- if custom_schema %}
         {{ custom_schema }}
    {%- else %}
         {{ target.schema }}
    {%- endif %}
{%- endmacro %}