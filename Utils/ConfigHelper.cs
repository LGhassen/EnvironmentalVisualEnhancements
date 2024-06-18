﻿using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using UnityEngine;

namespace Utils
{
    public class ConfigItem : System.Attribute
    {

    }
    public class Optional : System.Attribute
    {
    }

    public class ValueNode : System.Attribute
    {
    }

    public class NodeValue : System.Attribute
    {
    }

    public class ValueFilter : System.Attribute
    {
        private string fieldMask;

        public ValueFilter(string fieldMask)
        {
            this.fieldMask = fieldMask;
        }

        internal bool IsAllowed(string name)
        {
            return Regex.IsMatch(name, fieldMask);
        }
    }
    

    public class EnumMask : System.Attribute
    {
    }
    public class Conditional: System.Attribute
    {
        private string method;
        public string Method { get { return method; } }
        public Conditional(string method)
        {
            this.method = method;
        }
        public bool CheckConditional(Type T, ConfigNode config)
        {
            MethodInfo methodInfo = T.GetMethod(method);
            return (bool)methodInfo.Invoke(null, new object[] { config });
        }
    }

    public class ConfigWrapper 
    {
        public override String ToString(){ return name; }
        public ConfigNode Node { get { return node; } }
        string name;
        ConfigNode node;
        public ConfigWrapper(UrlDir.UrlConfig uc)
        {
            name = uc.parent.url;
            node = uc.config;
        }
    }

    public static class ConfigHelper
    {
        public const string BODY_FIELD = "body";
        public const string OBJECT_NODE = "OBJECT";

        public static bool ConditionsMet(FieldInfo field, FieldInfo parent, ConfigNode node)
        {
            bool isConditional = Attribute.IsDefined(field, typeof(Conditional));
            Conditional conditional = (Conditional)Attribute.GetCustomAttribute(field, typeof(Conditional));
            
            bool conditionsMet = true;

            conditionsMet &= ValueIsAllowed(field, parent);
            
            if (isConditional)
            {
                try
                {
                    conditionsMet &= conditional.CheckConditional(field.DeclaringType, node);
                }
                catch
                {
                    conditionsMet &= false;
                }
            }

            return conditionsMet;
        }

        public static bool ValueIsAllowed(FieldInfo field, FieldInfo parent)
        {
            bool isAllowed = true;
            if (!Attribute.IsDefined(field, typeof(NodeValue)))
            {
                ValueFilter filter = null;
                if(parent != null && Attribute.IsDefined(parent, typeof(ValueFilter)))
                {
                    filter = (ValueFilter)Attribute.GetCustomAttribute(parent, typeof(ValueFilter));
                }
                else if(Attribute.IsDefined(field.DeclaringType, typeof(ValueFilter)))
                {
                    filter = (ValueFilter)Attribute.GetCustomAttribute(field.DeclaringType, typeof(ValueFilter));
                }
                if (filter != null)
                {
                    isAllowed = filter.IsAllowed(field.Name);
                }
                
            }
            
            return isAllowed;
        }

        public static bool IsValueNode(FieldInfo field)
        {
            bool isNode = false;
            if (Attribute.IsDefined(field, typeof(ValueNode)))
            {
                isNode = true;
            }
            else if (Attribute.IsDefined(field.FieldType, typeof(ValueNode)))
            {
                isNode |= true;
            }

            return isNode;
        }

        public static bool IsNode(FieldInfo field, ConfigNode node, bool checkConfig = true)
        {
            bool isNode = field.FieldType.GetFields(BindingFlags.Instance | BindingFlags.NonPublic).Where(
               fi => Attribute.IsDefined(fi, typeof(ConfigItem))).Count() > 0 ? true : false;
             
            if(Attribute.IsDefined(field, typeof(ValueNode)))
            {
                if (checkConfig)
                {
                    isNode &= node.HasNode(field.Name);
                }
            }
            else if(Attribute.IsDefined(field.FieldType, typeof(ValueNode)))
            {
                if (checkConfig)
                {
                    isNode &= node.HasNode(field.Name);
                }
            }

            return isNode;
        }

        public static bool IsList(FieldInfo field)
        {
            return field.FieldType.IsGenericType && field.FieldType.GetGenericTypeDefinition() == typeof(List<>);
        }

        public static bool CanParse(FieldInfo field, String value, ConfigNode node = null)
        {
            object test = null;
            try
            {
                return Parse(field, ref test, new string[] { value }, node);
            }
            catch
            {
                return false;
            }
        }

        public static ConfigNode CreateConfigFromObject(object obj, ConfigNode node)
        {
            var objfields = obj.GetType().GetFields(BindingFlags.Instance | BindingFlags.NonPublic).Where(
                   field => Attribute.IsDefined(field, typeof(ConfigItem)));
            foreach (FieldInfo field in objfields)
            {
                string value = GetConfigValue(obj, field);
                node.SetValue(field.Name, value, true);
            }
            return node;
        }

        public static string GetConfigValue(object obj, FieldInfo field, int index = 0)
        {
            object value = field.GetValue(obj);
            if (field.FieldType == typeof(float))
            {
                try
                {
                    return ((float)value).ToString("G8");
                }
                catch { }
            }
            else if (field.FieldType == typeof(double))
            {
                try
                {
                    return ((double)value).ToString("G8");
                }
                catch { }
            }
            else if (field.FieldType == typeof(bool))
            {
                try
                {
                    return ((bool)value).ToString();
                }
                catch { }
            }
            else if (field.FieldType == typeof(String))
            {
                return (string)value;
            }
            else if (field.FieldType == typeof(Color))
            {
                try
                {
                    return ConfigNode.WriteColor((Color)value);
                }
                catch { }
            }
            else if (field.FieldType.IsEnum)
            {
                try
                {
                    return ConfigNode.WriteEnum((Enum) value);
                }
                catch { }
            }
            else if (field.FieldType == typeof(Matrix4x4))
            {
                try
                {
                    return ConfigNode.WriteMatrix4x4((Matrix4x4)value);
                }
                catch { }
            }
            else if (field.FieldType == typeof(Quaternion))
            {
                try
                {
                    return ConfigNode.WriteQuaternion((Quaternion)value);
                }
                catch { }
            }
            else if (field.FieldType == typeof(Vector2))
            {
                try
                {
                    return ConfigNode.WriteVector((Vector2)value);
                }
                catch { }
            }
            else if (field.FieldType == typeof(Vector3))
            {
                try
                {
                    return ConfigNode.WriteVector((Vector3)value);
                }
                catch { }
            }
            else if (field.FieldType == typeof(Vector4))
            {
                try
                {
                    return ConfigNode.WriteVector((Vector4)value);
                }
                catch { }
            }
            else if (field.FieldType == typeof(List<string>))
            {
                try
                {
                    List<string> list = (List<string>)value;
                    if(list.Count > index)
                    {
                        return list[index];
                    }
                    return "";
                }
                catch { }
            }
            else
            {
                bool isOptional = Attribute.IsDefined(field, typeof(Optional));
                bool valueNode = IsValueNode(field);
                
                if (valueNode && value != null)
                {
                    return (string)value.GetType().GetFields(BindingFlags.Instance | BindingFlags.NonPublic).First(
                   f => Attribute.IsDefined(f, typeof(NodeValue))).GetValue(value);
                }
                
                return "";
            }

            return "";
        }

        public static bool LoadObjectFromConfig(object obj, ConfigNode node)
        {
            var objfields = obj.GetType().GetFields(BindingFlags.Instance | BindingFlags.NonPublic).Where(
                   field => Attribute.IsDefined(field, typeof(ConfigItem)));
            foreach (FieldInfo field in objfields)
            {
                object objValue = null;
                bool canParse = false;
                try
                {
                    canParse = Parse(field, ref objValue, node.GetValues(field.Name), node.GetNode(field.Name));
                }
                catch(Exception e)
                {
                    throw new UnityException("Unable to parse \"" + field.Name + "\" in \"" + node.name + "\"!", e);
                }
                if (objValue != null)
                {
                    field.SetValue(obj, objValue);
                }
                if (!canParse)
                {
                    throw new UnityException("Unable to parse \"" + field.Name + "\" in \"" + node.name + "\"!");  
                }
                  
            }
            return true;
        }

        private static bool Parse(FieldInfo field, ref object obj, string[] value, ConfigNode node = null)
        {
            obj = null;
            if (field.FieldType == typeof(float))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = float.Parse(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to float"); }
            }
            else if (field.FieldType == typeof(double))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = double.Parse(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to double"); }
            }
            else if (field.FieldType == typeof(bool))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = bool.Parse(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to bool"); }
            }
            else if(field.FieldType == typeof(String))
            {
                if (value != null && value.Length > 0)
                {
                    obj = value[0];
                }
                return true;
            }
            else if(field.FieldType == typeof(Color))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = (Color)ConfigNode.ParseVector4(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to Color"); }
            }
            else if (field.FieldType.IsEnum)
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = ConfigNode.ParseEnum(field.FieldType, value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to enum "+field.FieldType); }
            }
            else if (field.FieldType == typeof(Matrix4x4))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = ConfigNode.ParseMatrix4x4(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to Matrix4x4"); }
            }
            else if (field.FieldType == typeof(Quaternion))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = ConfigNode.ParseQuaternion(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to Quaternion"); }
            }
            else if (field.FieldType == typeof(Vector2))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = (Vector2)ConfigNode.ParseVector2(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to Vector2"); }
            }
            else if (field.FieldType == typeof(Vector3))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = ConfigNode.ParseVector3(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to Vector3"); }
            }
            else if (field.FieldType == typeof(Vector4))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = ConfigNode.ParseVector4(value[0]);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value[0] + " to Vector4"); }
            }
            else if (field.FieldType == typeof(List<string>))
            {
                try
                {
                    if (value != null && value.Length > 0)
                    {
                        obj = new List<string>(value);
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value + " to List<string>"); }
            }
            else if (ConfigHelper.IsList(field))
            {
                var innerType = field.FieldType.GetGenericArguments()[0];

                try
                {
                    obj = Activator.CreateInstance(field.FieldType);

                    foreach (var itemNode in node.GetNodes("Item"))
                    {
                        var itemObject = Activator.CreateInstance(innerType);
                        LoadObjectFromConfig(itemObject, itemNode);
                        field.FieldType.GetMethod("Add").Invoke(obj, new[] { itemObject });
                    }
                    return true;
                }
                catch { throw new Exception("Can't parse " + value + " to List<"+ innerType.Name+">"); }
            }
            else if (field.FieldType == typeof(FloatCurve))
            {
                var nodeToLoad = node != null ? node : ConfigNode.Parse(value[0]).GetNodes()[0];

                obj = new FloatCurve();
                ((FloatCurve)obj).Load(nodeToLoad);

                return true;
            }
            else
            {
                bool isOptional = Attribute.IsDefined(field, typeof(Optional));
                bool valueNode = IsValueNode(field);

                ConstructorInfo ctor = field.FieldType.GetConstructor(System.Type.EmptyTypes);
                
                
                if (node != null)
                {
                    obj = ctor.Invoke(null);
                    LoadObjectFromConfig(obj, node);
                }
                else if(valueNode && value != null && value.Length > 0)
                {
                    obj = ctor.Invoke(null);
                    obj.GetType().GetFields(BindingFlags.Instance | BindingFlags.NonPublic).First(
                   f => Attribute.IsDefined(f, typeof(NodeValue))).SetValue(obj, value[0]);
                }
                else if (!isOptional)
                {
                    obj = ctor.Invoke(null);
                }

                MethodInfo validate = field.FieldType.GetMethod("isValid");
                if (validate != null && obj != null)
                {
                    return (bool)validate.Invoke(obj, null);
                }
                
                return true;
            }
            
        }

    }
}
