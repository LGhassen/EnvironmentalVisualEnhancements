using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using UnityEngine;

namespace Utils
{
    public class GUIHidden : Attribute
    {

    }

    public class ConfigName : Attribute
    {
        string name;
        public string Name { get { return name; } }
        public ConfigName(string name)
        {
            this.name = name;
        }
    }


    public struct FieldMeta
    {
        public FieldInfo Field;
        public bool IsHidden;
        public bool IsOptional;
        public string Tooltip;
        public bool StartsCollapsed;
    }

    public static class GUIHelper
    {
        public const float spacingOffset = .25f;
        public const float elementHeight = 22;
        public const float valueRatio = (3f / 10);

        public const string UP_ARROW = "\u2191";//"\u23f6";
        public const string DOWN_ARROW = "\u2193";//"\u23f7";
        public const string LEFT_ARROW = "\u2190";//"\u23f4";
        public const string RIGHT_ARROW = "\u2192";//"\u23f5";

        private static readonly Dictionary<Type, FieldMeta[]> _configFieldCache =
            new Dictionary<Type, FieldMeta[]>();

        private static readonly Dictionary<Type, string[]> _enumNameCache =
            new Dictionary<Type, string[]>();

        private static readonly Dictionary<Type, string> _nodeValueFieldCache =
            new Dictionary<Type, string>();

        private static readonly Dictionary<Type, string> _configNameCache =
            new Dictionary<Type, string>();

        private static readonly Dictionary<Type, Type> _genericArgCache =
            new Dictionary<Type, Type>();

        public static FieldMeta[] GetCachedConfigFields(Type t)
        {
            if (!_configFieldCache.TryGetValue(t, out var metas))
            {
                var fields = t.GetFields(BindingFlags.Instance | BindingFlags.NonPublic)
                    .Where(f => Attribute.IsDefined(f, typeof(ConfigItem)))
                    .ToArray();

                metas = new FieldMeta[fields.Length];
                for (int i = 0; i < fields.Length; i++)
                {
                    var f = fields[i];
                    string tip = null;
                    if (Attribute.IsDefined(f, typeof(TooltipAttribute)))
                    {
                        tip = ((TooltipAttribute)Attribute.GetCustomAttribute(
                            f, typeof(TooltipAttribute))).tooltip;
                    }
                    metas[i] = new FieldMeta
                    {
                        Field = f,
                        IsHidden = Attribute.IsDefined(f, typeof(GUIHidden)),
                        IsOptional = Attribute.IsDefined(f, typeof(Optional)),
                        Tooltip = tip,
                        StartsCollapsed = Attribute.IsDefined(f, typeof(CollapsedList)),
                    };
                }
                _configFieldCache[t] = metas;
            }
            return metas;
        }

        public static string[] GetCachedEnumNames(Type enumType)
        {
            if (!_enumNameCache.TryGetValue(enumType, out var names))
            {
                names = enumType.GetFields()
                    .Where(m => m.IsLiteral && !Attribute.IsDefined(m, typeof(EnumMask)))
                    .Select(m => m.Name)
                    .ToArray();
                _enumNameCache[enumType] = names;
            }
            return names;
        }

        public static string GetCachedNodeValueField(Type t)
        {
            if (!_nodeValueFieldCache.TryGetValue(t, out var name))
            {
                name = t.GetFields(BindingFlags.Instance | BindingFlags.NonPublic)
                    .First(f => Attribute.IsDefined(f, typeof(NodeValue))).Name;
                _nodeValueFieldCache[t] = name;
            }
            return name;
        }

        public static string GetCachedConfigName(Type t)
        {
            if (!_configNameCache.TryGetValue(t, out var name))
            {
                name = ((ConfigName)Attribute.GetCustomAttribute(t, typeof(ConfigName))).Name;
                _configNameCache[t] = name;
            }
            return name;
        }

        private static Type GetCachedGenericArg(Type t)
        {
            if (!_genericArgCache.TryGetValue(t, out var arg))
            {
                arg = t.GetGenericArguments()[0];
                _genericArgCache[t] = arg;
            }
            return arg;
        }

        private struct HeightCacheKey : IEquatable<HeightCacheKey>
        {
            private readonly ConfigNode _node;
            private readonly Type _type;
            private readonly FieldInfo _parent;
            private readonly int _hash;

            public HeightCacheKey(ConfigNode node, Type type, FieldInfo parent)
            {
                _node = node;
                _type = type;
                _parent = parent;
                unchecked
                {
                    int h = node != null
                        ? System.Runtime.CompilerServices.RuntimeHelpers.GetHashCode(node)
                        : 0;
                    h = h * 31 + (type != null ? type.GetHashCode() : 0);
                    h = h * 31 + (parent != null ? parent.GetHashCode() : 0);
                    _hash = h;
                }
            }

            public bool Equals(HeightCacheKey other)
            {
                return ReferenceEquals(_node, other._node)
                    && _type == other._type
                    && _parent == other._parent;
            }

            public override bool Equals(object obj)
            {
                return obj is HeightCacheKey other && Equals(other);
            }

            public override int GetHashCode() { return _hash; }
        }

        private static readonly Dictionary<HeightCacheKey, float> _heightCache =
            new Dictionary<HeightCacheKey, float>();

        private static int _lastHeightCacheFrame = -1;

        private struct ListStateKey : IEquatable<ListStateKey>
        {
            private readonly ConfigNode _node;
            private readonly string _fieldName;
            private readonly int _hash;

            public ListStateKey(ConfigNode node, string fieldName)
            {
                _node = node;
                _fieldName = fieldName;
                unchecked
                {
                    int h = node != null
                        ? System.Runtime.CompilerServices.RuntimeHelpers.GetHashCode(node)
                        : 0;
                    h = h * 31 + (fieldName != null ? fieldName.GetHashCode() : 0);
                    _hash = h;
                }
            }

            public bool Equals(ListStateKey other)
                => ReferenceEquals(_node, other._node) && _fieldName == other._fieldName;

            public override bool Equals(object obj)
                => obj is ListStateKey other && Equals(other);

            public override int GetHashCode() { return _hash; }
        }

        // Persistent per-list collapsed/expanded state. Keyed by (parent config node, field name).
        private static readonly Dictionary<ListStateKey, bool> _listExpandedState =
            new Dictionary<ListStateKey, bool>();

        private static bool IsListExpanded(ConfigNode parentNode, FieldInfo field, bool startsCollapsed)
        {
            var key = new ListStateKey(parentNode, field.Name);
            bool expanded;
            if (!_listExpandedState.TryGetValue(key, out expanded))
            {
                expanded = !startsCollapsed;
                _listExpandedState[key] = expanded;
            }
            return expanded;
        }

        private static void SetListExpanded(ConfigNode parentNode, FieldInfo field, bool expanded)
        {
            _listExpandedState[new ListStateKey(parentNode, field.Name)] = expanded;
        }

        public static void ValidateHeightCache()
        {
            int frame = Time.frameCount;
            if (frame != _lastHeightCacheFrame)
            {
                _heightCache.Clear();
                _lastHeightCacheFrame = frame;
            }
        }


        private static float _vpTop = float.NegativeInfinity;
        private static float _vpBottom = float.PositiveInfinity;

        public static void SetScrollViewport(Vector2 scrollPos, float viewportHeight)
        {
            _vpTop = scrollPos.y;
            _vpBottom = scrollPos.y + viewportHeight;
        }

        public static void ClearScrollViewport()
        {
            _vpTop = float.NegativeInfinity;
            _vpBottom = float.PositiveInfinity;
        }

        private static bool IsRangeVisible(float top, float bottom)
        {
            return bottom > _vpTop && top < _vpBottom;
        }

        private static GUISkin _cachedSkin;
        private static GUIStyle _styleLabel;
        private static GUIStyle _styleLabelCenter;
        private static GUIStyle _styleTextField;
        private static GUIStyle _styleTextFieldRed;
        private static GUIStyle _styleTextArea;
        private static GUIStyle _styleTextAreaRed;

        private static Texture2D _separatorTexture;

        private static Texture2D GetSeparatorTexture()
        {
            if (_separatorTexture == null)
            {
                _separatorTexture = new Texture2D(1, 1);
                _separatorTexture.hideFlags = HideFlags.HideAndDontSave;
                _separatorTexture.SetPixel(0, 0, Color.white);
                _separatorTexture.Apply();
            }

            return _separatorTexture;
        }

        public static void EnsureStyles()
        {
            if (_cachedSkin == GUI.skin) return;
            _cachedSkin = GUI.skin;

            _styleLabel = new GUIStyle(GUI.skin.label);
            _styleLabelCenter = new GUIStyle(GUI.skin.label)
            {
                alignment = TextAnchor.MiddleCenter
            };
            _styleTextField = new GUIStyle(GUI.skin.textField);

            _styleTextFieldRed = new GUIStyle(GUI.skin.textField);
            _styleTextFieldRed.normal.textColor = Color.red;
            _styleTextFieldRed.active.textColor = Color.red;
            _styleTextFieldRed.focused.textColor = Color.red;
            _styleTextFieldRed.hover.textColor = Color.red;

            _styleTextArea = new GUIStyle(GUI.skin.textArea);

            _styleTextAreaRed = new GUIStyle(GUI.skin.textArea);
            _styleTextAreaRed.normal.textColor = Color.red;
            _styleTextAreaRed.active.textColor = Color.red;
            _styleTextAreaRed.focused.textColor = Color.red;
            _styleTextAreaRed.hover.textColor = Color.red;
        }


        public static float GetNodeHeightCount(ConfigNode node, Type T, FieldInfo parent)
        {
            var key = new HeightCacheKey(node, T, parent);
            float cached;
            if (_heightCache.TryGetValue(key, out cached))
                return cached;

            float result = ComputeNodeHeightCount(node, T, parent);
            _heightCache[key] = result;
            return result;
        }

        private static float ComputeNodeHeightCount(ConfigNode node, Type T, FieldInfo parent)
        {
            return 1f + (2f * spacingOffset) + ComputeFieldsHeightCount(node, T, parent);
        }

        private static float ComputeFieldsHeightCount(ConfigNode node, Type T, FieldInfo parent)
        {
            float fieldCount = 0f;

            // When T itself is a list type (e.g. List<X>), compute height from
            // its item nodes rather than looking for ConfigItem fields on List<X>
            // (which has none).  HandleGUI adds 4*spacingOffset between items.
            if (typeof(IList).IsAssignableFrom(T) && T.IsGenericType && node != null)
            {
                var innerType = GetCachedGenericArg(T);
                var itemNodes = node.GetNodes();
                for (int i = 0; i < itemNodes.Length; i++)
                {
                    fieldCount += ComputeFieldsHeightCount(itemNodes[i], innerType, null);
                    if (i < itemNodes.Length - 1)
                    {
                        fieldCount += 4 * spacingOffset;
                    }
                }
                return fieldCount;
            }

            FieldMeta[] metas = GetCachedConfigFields(T);

            foreach (FieldMeta meta in metas)
            {
                FieldInfo field = meta.Field;
                bool isNode = ConfigHelper.IsNode(field, node, false);

                if (node != null && (parent == null || ConfigHelper.ConditionsMet(field, parent, node)))
                {
                    if (field.FieldType == typeof(FloatCurve))
                    {
                        fieldCount += spacingOffset;
                        fieldCount += GetFloatCurveHeight(node, field.Name);
                    }
                    else if (isNode)
                    {
                        if (node.HasNode(field.Name))
                        {
                            fieldCount += GetNodeHeightCount(node.GetNode(field.Name), field.FieldType, field);
                        }
                        else
                        {
                            fieldCount += GetNodeHeightCount(null, field.FieldType, field);
                        }
                        fieldCount += spacingOffset;
                    }
                    else if (ConfigHelper.IsList(field))
                    {
                        bool expanded = IsListExpanded(node, field, meta.StartsCollapsed);
                        if (!expanded || !typeof(IList).IsAssignableFrom(field.FieldType) || !node.HasNode(field.Name))
                        {
                            // Collapsed or no data: only the header row.
                            fieldCount += 1f + spacingOffset;
                        }
                        else
                        {
                            var itemNodes = node.GetNode(field.Name).GetNodes();
                            Type innerType = GetCachedGenericArg(field.FieldType);

                            fieldCount += 1f + spacingOffset;

                            for (int i = 0; i < itemNodes.Length; i++)
                            {
                                // List items are rendered inline (HandleGUI iterates
                                // their fields directly), so use fields-only height.
                                fieldCount += ComputeFieldsHeightCount(itemNodes[i], innerType, null);

                                if (i < itemNodes.Length - 1)
                                {
                                    fieldCount += 4f * spacingOffset;
                                }
                            }
                        }
                    }
                    else if (!meta.IsHidden)
                    {
                        fieldCount += 1f + spacingOffset;
                    }
                }
            }

            return fieldCount;
        }

        public static Rect GetRect(Rect placementBase, ref Rect placement, ConfigNode node, Type T, FieldInfo field)
        {
            placement.height = GetNodeHeightCount(node, T, field);
            float width = placementBase.width;
            float height;

            float x = (placement.x * width) + placementBase.x;
            float y = (placement.y * elementHeight) + placementBase.y;
            width += placement.width;
            height = (elementHeight * placement.height);
            return new Rect(x, y, width - 10, height);
        }

        public static Rect GetRect(Rect placementBase, ref Rect placement)
        {
            float width = placementBase.width;
            float height;

            float x = (placement.x * width) + placementBase.x;
            float y = (placement.y * elementHeight) + placementBase.y;
            width += placement.width;
            height = (elementHeight * placement.height);
            return new Rect(x, y, width - 10, height);
        }

        public static void SplitRect(ref Rect rect1, ref Rect rect2, float ratio)
        {
            float width = rect1.width;
            rect1.width *= ratio;
            if (rect2 != null)
            {
                rect2.width = width * (1 - ratio);
                rect2.x = rect1.x + rect1.width;
            }
        }

        private static CelestialBody GetMapBody()
        {
            if (MapView.MapIsEnabled)
            {
                MapObject target = MapView.MapCamera.target;
                switch (target.type)
                {
                    case MapObject.ObjectType.CelestialBody:
                        return target.celestialBody;
                    case MapObject.ObjectType.ManeuverNode:
                        return target.maneuverNode.patch.referenceBody;
                    case MapObject.ObjectType.Vessel:
                        return target.vessel.mainBody;
                }
            }
            else if (HighLogic.LoadedScene == GameScenes.MAINMENU)
            {
                CelestialBody[] celestialBodies = FlightGlobals.Bodies.ToArray();
                return celestialBodies.First<CelestialBody>(cb => cb.isHomeWorld);
            }
            else
            {
                return FlightGlobals.currentMainBody;
            }
            return null;
        }

        public static String DrawBodySelector(Rect placementBase, ref Rect placement)
        {
            List<String> celestialBodies = FlightGlobals.Bodies.ConvertAll(x => x.bodyName);
            CelestialBody currentBody = GUIHelper.GetMapBody();
            if (currentBody != null)
            {
                String body = DrawSelector<String>(celestialBodies.ToList(), currentBody.bodyName, 4, placementBase, ref placement);
                if (MapView.MapIsEnabled || HighLogic.LoadedScene == GameScenes.TRACKSTATION)
                {
                    if (body != currentBody.bodyName)
                    {
                        MapView.MapCamera.SetTarget(body);
                    }
                }
            }
            return currentBody.bodyName;
        }

        public static ConfigNode DrawObjectSelector<T>(ConfigNode sourceNode, ref int selectedObjIndex, ref String objString, ref Vector2 objListPos, Rect placementBase, ref Rect placement, ConfigNode.Value filter = null)
        {
            EnsureStyles();

            List<ConfigNode> nodeList;
            if (filter != null)
            {
                nodeList = sourceNode.GetNodes(ConfigHelper.OBJECT_NODE, filter.name, filter.value).ToList();
            }
            else
            {
                nodeList = sourceNode.GetNodes().ToList();
            }

            string configName = GetCachedConfigName(typeof(T));

            String[] objList = nodeList.Select(node => node.GetValue(configName)).ToArray();
            float nodeHeight = placement.height;
            Rect selectBoxOutlineRect = GetRect(placementBase, ref placement);
            placement.height = nodeHeight - 1;
            Rect selectBoxRect = GetRect(placementBase, ref placement);
            placement.height = nodeList.Count;
            Rect selectBoxItemsRect = GetRect(placementBase, ref placement);

            placement.height = 1;
            Rect optButtonRect = GetRect(placementBase, ref placement);
            SplitRect(ref selectBoxRect, ref optButtonRect, (15f / 16));


            GUI.Box(selectBoxOutlineRect, "");
            selectBoxRect.x += 10;
            selectBoxRect.width -= 20;
            selectBoxRect.y += 10;
            selectBoxRect.height -= 20;

            selectBoxItemsRect.x = 0;
            selectBoxItemsRect.y = 0;
            if (nodeList.Count <= 3)
            {
                selectBoxItemsRect.width = selectBoxRect.width;
            }
            else
            {
                selectBoxItemsRect.width = selectBoxRect.width - 20;
            }

            objListPos = GUI.BeginScrollView(selectBoxRect, objListPos, selectBoxItemsRect);
            int oldselectedObjIndex = selectedObjIndex;
            if (selectedObjIndex == -1)
            {
                selectedObjIndex = 0;
            }
            selectedObjIndex = GUI.SelectionGrid(selectBoxItemsRect, selectedObjIndex, objList, 1);
            GUI.EndScrollView();
            placement.y += nodeHeight - 1;

            optButtonRect.x -= 5;
            optButtonRect.y += 10;
            if (nodeList.Count > 0)
            {
                if (GUI.Button(optButtonRect, UP_ARROW) && selectedObjIndex > 0)
                {
                    int moveIndex = selectedObjIndex;
                    ConfigNode item = nodeList[--selectedObjIndex];
                    nodeList.Remove(item);
                    nodeList.Add(item);
                    sourceNode.RemoveNode(item);
                    sourceNode.AddNode(item);
                    for (int i = moveIndex; i < nodeList.Count - 1; i++)
                    {
                        item = nodeList[moveIndex];
                        nodeList.Remove(item);
                        nodeList.Add(item);
                        sourceNode.RemoveNode(item);
                        sourceNode.AddNode(item);
                    }
                }
                optButtonRect.y += optButtonRect.height * (nodeHeight - 3);
                if (GUI.Button(optButtonRect, DOWN_ARROW) && selectedObjIndex < nodeList.Count - 1)
                {

                    ConfigNode item = nodeList[selectedObjIndex];
                    nodeList.Remove(item);
                    nodeList.Add(item);
                    sourceNode.RemoveNode(item);
                    sourceNode.AddNode(item);
                    int moveIndex = ++selectedObjIndex;
                    for (int i = moveIndex; i < nodeList.Count - 1; i++)
                    {
                        item = nodeList[moveIndex];
                        nodeList.Remove(item);
                        nodeList.Add(item);
                        sourceNode.RemoveNode(item);
                        sourceNode.AddNode(item);
                    }
                }
            }
            Rect listEditTextRect = GetRect(placementBase, ref placement);
            listEditTextRect.x += 10;
            listEditTextRect.width -= 20;
            listEditTextRect.y -= 5;

            Rect listEditRect = new Rect(listEditTextRect);
            Rect listAddRect = new Rect(listEditTextRect);
            Rect listRemoveRect = new Rect(listEditTextRect);

            SplitRect(ref listEditTextRect, ref listEditRect, (1f / 2));
            SplitRect(ref listEditRect, ref listAddRect, (1f / 3));
            SplitRect(ref listAddRect, ref listRemoveRect, (1f / 2));

            listEditTextRect.width -= 5;
            listEditRect.width -= 5;
            listAddRect.width -= 5;
            listRemoveRect.width -= 5;

            if (selectedObjIndex != oldselectedObjIndex && nodeList.Count > 0)
            {
                objString = nodeList[selectedObjIndex].GetValue(configName);
            }
            objString = GUI.TextField(listEditTextRect, objString);
            String name = objString;
            if (objString.Length > 0 && !objString.Contains(' ') && !nodeList.Exists(n => n.GetValue(configName) == name))
            {
                if (nodeList.Count > 0 && GUI.Button(listEditRect, "#"))
                {
                    nodeList[selectedObjIndex].SetValue(configName, objString, true);
                }
                if (GUI.Button(listAddRect, "+"))
                {
                    ConfigNode newNode = new ConfigNode(ConfigHelper.OBJECT_NODE);
                    newNode.SetValue(configName, objString, true);
                    if (filter != null)
                    {
                        newNode.SetValue(filter.name, filter.value, true);
                    }
                    nodeList.Add(newNode);
                    sourceNode.AddNode(newNode);
                }
            }
            else
            {
                listEditRect.width += listAddRect.width;
                GUI.Label(listEditRect, "Enter unique name to add new element");
            }
            if (nodeList.Count > 0 && GUI.Button(listRemoveRect, "-"))
            {
                ConfigNode item = nodeList[selectedObjIndex];
                nodeList.Remove(item);
                sourceNode.RemoveNode(item);
                if (selectedObjIndex >= nodeList.Count)
                {
                    selectedObjIndex = nodeList.Count - 1;
                }
            }
            placement.y += 1 + spacingOffset;

            if (nodeList.Count == 0)
            {
                return null;
            }
            return nodeList[selectedObjIndex];
        }

        public static T DrawSelector<T>(List<T> objList, T selectedObj, float ratio, Rect placementBase, ref Rect placement)
        {
            int selectedIndex = objList.IndexOf(selectedObj);
            return DrawSelector<T>(objList, ref selectedIndex, ratio, placementBase, ref placement);
        }

        public static T DrawSelector<T>(List<T> objList, ref int selectedIndex, float ratio, Rect placementBase, ref Rect placement)
        {
            EnsureStyles();

            Rect leftRect = GUIHelper.GetRect(placementBase, ref placement);
            Rect centerRect = GUIHelper.GetRect(placementBase, ref placement);
            Rect rightRect = GUIHelper.GetRect(placementBase, ref placement);
            GUIHelper.SplitRect(ref leftRect, ref centerRect, 1f / (ratio));
            GUIHelper.SplitRect(ref centerRect, ref rightRect, (ratio - 2) / (ratio - 1));

            if (objList.Count > 1 && GUI.Button(leftRect, LEFT_ARROW))
            {
                selectedIndex--;
                if (selectedIndex < 0)
                {
                    selectedIndex = objList.Count - 1;
                }
            }
            if (objList.Count > 1 && GUI.Button(rightRect, RIGHT_ARROW))
            {
                selectedIndex++;
                if (selectedIndex >= objList.Count)
                {
                    selectedIndex = 0;
                }
            }
            T currentObj = default(T);
            if (selectedIndex < objList.Count)
            {
                currentObj = objList[selectedIndex];
                if (currentObj != null)
                {
                    GUI.Label(centerRect, currentObj.ToString(), _styleLabelCenter);
                }

            }
            placement.y += 1 + spacingOffset;
            return currentObj;
        }

        private static Dictionary<ConfigNode, string> floatCurveTemporaryValues = new Dictionary<ConfigNode, string>();
        private static Dictionary<ConfigNode, bool> floatCurveShowKeys = new Dictionary<ConfigNode, bool>();
        private static Dictionary<ConfigNode, int> floatCurveLastHash = new Dictionary<ConfigNode, int>();

        private static bool GetShowKeys(ConfigNode node)
        {
            bool v;
            return floatCurveShowKeys.TryGetValue(node, out v) && v;
        }

        // Height in placement units for the FloatCurve editor block
        public static float GetFloatCurveHeight(ConfigNode parentNode, string fieldName)
        {
            // 1 label + 10 curve + 1 button = 12 base
            float h = 12f;
            if (parentNode != null)
            {
                var sub = parentNode.GetNode(fieldName);
                if (sub != null && GetShowKeys(sub))
                    h += 6f; // textbox
            }
            return h;
        }

        private static int ComputeNodeValueHash(ConfigNode node)
        {
            unchecked
            {
                int h = 17;
                foreach (string v in node.GetValuesStartsWith("key"))
                    h = h * 31 + v.GetHashCode();
                return h;
            }
        }

        private static string NodeKeysToText(ConfigNode node)
        {
            var sb = new System.Text.StringBuilder();
            foreach (string v in node.GetValuesStartsWith("key"))
            {
                if (sb.Length > 0) sb.Append('\n');
                sb.Append(v);
            }
            return sb.ToString();
        }

        // Returns true if every non-empty line has 2 or 4 valid floats (time value [inTangent outTangent]).
        private static bool CanParseKeys(string text)
        {
            if (string.IsNullOrEmpty(text)) return true;
            string[] lines = text.Split(new[] { '\n', '\r' },
                StringSplitOptions.RemoveEmptyEntries);
            foreach (string line in lines)
            {
                string trimmed = line.Trim();
                if (trimmed.Length == 0) continue;
                string[] parts = trimmed.Split(new[] { ' ', '\t' },
                    StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length != 2 && parts.Length != 4) return false;
                float dummy;
                foreach (string p in parts)
                    if (!float.TryParse(p, out dummy)) return false;
            }
            return true;
        }

        public static void DrawField(Rect placementBase, ref Rect placement, object obj, FieldMeta meta, ConfigNode config)
        {
            EnsureStyles();

            FieldInfo field = meta.Field;

            if (field.FieldType == typeof(FloatCurve))
            {
                placement.y += spacingOffset;

                var subNode = config.GetNode(field.Name);
                if (subNode == null)
                {
                    subNode = config.AddNode(field.Name);
                }

                // label
                placement.height = 1;
                Rect labelRect = GUIHelper.GetRect(placementBase, ref placement);
                String tooltipText = meta.Tooltip ?? "";
                GUIContent gc = new GUIContent(field.Name, tooltipText);
                GUI.Label(labelRect, gc);
                placement.y += 1f;

                // curve editor, 10 lines
                placement.height = 10;
                Rect curveRect = GUIHelper.GetRect(placementBase, ref placement);
                CurveEditor.DrawCurveEditor(curveRect, subNode);
                placement.y += 10f;

                // "Show Keys" / "Hide Keys" button, 1 line
                placement.height = 1;
                Rect btnRect = GUIHelper.GetRect(placementBase, ref placement);
                bool showKeys = GetShowKeys(subNode);
                if (GUI.Button(btnRect, showKeys ? "Hide Keys" : "Show Keys"))
                {
                    showKeys = !showKeys;
                    floatCurveShowKeys[subNode] = showKeys;

                    // when opening, seed the text from the current node
                    if (showKeys)
                    {
                        floatCurveTemporaryValues[subNode] = NodeKeysToText(subNode);
                        floatCurveLastHash[subNode] = ComputeNodeValueHash(subNode);
                    }
                }
                placement.y += 1f;

                // editable key textbox
                if (showKeys)
                {
                    // detect if CurveEditor changed the node behind our back
                    int currentHash = ComputeNodeValueHash(subNode);
                    int lastHash;
                    if (!floatCurveLastHash.TryGetValue(subNode, out lastHash))
                        lastHash = 0;

                    if (currentHash != lastHash)
                    {
                        // curve editor moved a key — refresh text
                        floatCurveTemporaryValues[subNode] = NodeKeysToText(subNode);
                        floatCurveLastHash[subNode] = currentHash;
                    }

                    if (!floatCurveTemporaryValues.ContainsKey(subNode))
                        floatCurveTemporaryValues[subNode] = NodeKeysToText(subNode);

                    string textValue = floatCurveTemporaryValues[subNode];

                    placement.height = 6;
                    Rect textAreaRect = GUIHelper.GetRect(placementBase, ref placement);
                    GUIStyle fieldStyle = CanParseKeys(textValue) ? _styleTextArea : _styleTextAreaRed;

                    string newTextValue = GUI.TextArea(textAreaRect, textValue, fieldStyle);

                    if (newTextValue != textValue)
                    {
                        floatCurveTemporaryValues[subNode] = newTextValue;

                        // if it parses, write back to the ConfigNode
                        if (CanParseKeys(newTextValue))
                        {
                            subNode.ClearValues();
                            string[] lines = newTextValue.Split(new[] { '\n', '\r' },
                                StringSplitOptions.RemoveEmptyEntries);
                            foreach (string line in lines)
                            {
                                string trimmed = line.Trim();
                                if (trimmed.Length > 0)
                                    subNode.AddValue("key", trimmed);
                            }
                            floatCurveLastHash[subNode] = ComputeNodeValueHash(subNode);
                        }
                    }

                    placement.y += 6f;
                }
            }
            else if (!meta.IsHidden)
            {
                placement.y += spacingOffset;
                placement.height = 1;
                String value = config.GetValue(field.Name);

                String defaultValue = ConfigHelper.GetConfigValue(obj, field);
                if (value == null)
                {
                    if (defaultValue == null)
                    {
                        defaultValue = "";
                    }
                    value = defaultValue;
                }

                Rect labelRect = GUIHelper.GetRect(placementBase, ref placement);
                Rect fieldRect = GUIHelper.GetRect(placementBase, ref placement);
                GUIHelper.SplitRect(ref labelRect, ref fieldRect, valueRatio);

                String tooltipText = meta.Tooltip ?? "";
                GUIContent gc = new GUIContent(field.Name, tooltipText);

                Vector2 labelSize = _styleLabel.CalcSize(gc);
                labelRect.width = Mathf.Min(labelSize.x, labelRect.width);
                GUI.Label(labelRect, gc);

                string newValue = value;
                if (field.FieldType.IsEnum)
                {
                    newValue = ComboBox(fieldRect, value, GetCachedEnumNames(field.FieldType));
                }
                else
                {
                    GUIStyle fieldStyle = (value != "" && !ConfigHelper.CanParse(field, value))
                        ? _styleTextFieldRed
                        : _styleTextField;
                    newValue = GUI.TextField(fieldRect, value, fieldStyle);
                }

                if (newValue != defaultValue && value != newValue)
                {
                    config.SetValue(field.Name, newValue, true);

                }
                else if (newValue == defaultValue && config.HasValue(field.Name))
                {
                    config.RemoveValue(field.Name);
                }
                placement.y += 1f;
            }
        }

        private static string ComboBox(Rect fieldRect, string value, string[] list)
        {
            EnsureStyles();

            Rect fieldRectUp = new Rect(fieldRect);
            fieldRectUp.x += fieldRect.width - (2 * elementHeight);
            fieldRectUp.width = elementHeight;
            Rect fieldRectDown = new Rect(fieldRectUp);
            fieldRectDown.x += fieldRectDown.width;
            fieldRect.width -= 2 * fieldRectUp.width;
            GUI.Box(fieldRect, value, _styleTextField);

            if (GUI.Button(fieldRectUp, LEFT_ARROW, _styleTextField))
            {
                int index = Array.IndexOf(list, value);
                index--;
                if (index < 0)
                {
                    index = list.Length - 1;
                }
                value = list[index];
            }
            if (GUI.Button(fieldRectDown, RIGHT_ARROW, _styleTextField))
            {
                int index = Array.IndexOf(list, value);
                index++;
                if (index >= list.Length)
                {
                    index = 0;
                }
                value = list[index];
            }
            return value;
        }


        public static void HandleGUI(object obj, FieldInfo objInfo, ConfigNode configNode, Rect placementBase, ref Rect placement)
        {
            EnsureStyles();

            FieldMeta[] metas = GetCachedConfigFields(obj.GetType());

            foreach (FieldMeta meta in metas)
            {
                FieldInfo field = meta.Field;

                bool isNode = ConfigHelper.IsNode(field, configNode);

                bool isValueNode = ConfigHelper.IsValueNode(field);

                bool isList = ConfigHelper.IsList(field);

                if (isNode || isValueNode || isList)
                {
                    placement.y += spacingOffset;

                    ConfigNode node = configNode.GetNode(field.Name);

                    Rect boxRect = GUIHelper.GetRect(placementBase, ref placement, node, field.FieldType, field);

                    // viewport culling: skip entire node section
                    if (!IsRangeVisible(boxRect.y, boxRect.y + boxRect.height))
                    {
                        // placement.height == H (set by GetRect).
                        // Total advance from (y0+spacingOffset) = H, landing at y0+H+spacingOffset.
                        placement.y += placement.height;
                        continue;
                    }

                    GUI.Box(boxRect, "", _styleTextField);
                    placement.height = 1;
                    placement.y += spacingOffset;

                    Rect boxPlacementBase = new Rect(placementBase);
                    boxPlacementBase.x += 10;
                    Rect boxPlacement = new Rect(placement);
                    boxPlacement.width -= 20;

                    Rect toggleRect = GUIHelper.GetRect(boxPlacementBase, ref boxPlacement);
                    Rect titleRect = GUIHelper.GetRect(boxPlacementBase, ref boxPlacement);
                    Rect fieldRect = GUIHelper.GetRect(placementBase, ref boxPlacement);
                    if (isValueNode)
                    {
                        GUIHelper.SplitRect(ref titleRect, ref fieldRect, valueRatio);
                    }
                    GUIHelper.SplitRect(ref toggleRect, ref titleRect, (1f / 16));

                    String tooltipText = meta.Tooltip ?? "";
                    GUIContent gc = new GUIContent(field.Name, tooltipText);
                    Vector2 labelSize = _styleLabel.CalcSize(gc);

                    Rect listCollapseRec = new Rect(titleRect);
                    Rect listPlusRec = new Rect(titleRect);
                    Rect listMinusRec = new Rect(titleRect);

                    if (isList)
                    {
                        // Pin +/- to fixed width at the right end
                        float btnWidth = elementHeight;
                        listMinusRec = new Rect(titleRect.x + titleRect.width - btnWidth,
                                                titleRect.y, btnWidth, titleRect.height);
                        listPlusRec  = new Rect(listMinusRec.x - btnWidth,
                                                titleRect.y, btnWidth, titleRect.height);

                        // Label takes its natural width, capped so the collapse button always has room
                        titleRect.width = Mathf.Min(labelSize.x, listPlusRec.x - titleRect.x - btnWidth);

                        // Collapse button is half the gap width, centered in it
                        float gapLeft  = titleRect.x + titleRect.width;
                        float gapWidth = listPlusRec.x - gapLeft;
                        float colBtnWidth = gapWidth * 0.5f;
                        listCollapseRec = new Rect(gapLeft + (gapWidth - colBtnWidth) * 0.5f, titleRect.y,
                                                   colBtnWidth, titleRect.height);
                    }
                    else
                    {
                        titleRect.width = Mathf.Min(labelSize.x, titleRect.width);
                    }

                    GUI.Label(titleRect, gc);

                    bool removeable = node == null ? false : true;

                    bool conditionsMet = true;
                    if (objInfo != null)
                        conditionsMet = ConfigHelper.ConditionsMet(field, objInfo, configNode);

                    if (conditionsMet)
                    {
                        if (meta.IsOptional || isValueNode)
                        {
                            String value = null;
                            String defaultValue = ConfigHelper.GetConfigValue(obj, field);
                            String valueField = "";
                            if (isValueNode)
                            {
                                valueField = GetCachedNodeValueField(field.FieldType);
                            }
                            String newValue = "";
                            if (isValueNode)
                            {
                                if (configNode.HasValue(field.Name))
                                {
                                    value = configNode.GetValue(field.Name);
                                }
                                else if (node != null && node.HasValue(valueField))
                                {
                                    value = node.GetValue(valueField);
                                }

                                if (value == null)
                                {
                                    if (defaultValue == null)
                                    {
                                        defaultValue = "";
                                    }
                                    value = defaultValue;
                                }

                                GUIStyle fieldStyle = (value != "" && !ConfigHelper.CanParse(field, value, node))
                                    ? _styleTextFieldRed
                                    : _styleTextField;
                                newValue = GUI.TextField(fieldRect, value, fieldStyle);

                            }
                            bool toggle = removeable != GUI.Toggle(toggleRect, removeable, "");
                            if (toggle)
                            {
                                if (removeable)
                                {
                                    configNode.RemoveNode(field.Name);
                                    node = null;
                                }
                                else
                                {
                                    node = configNode.AddNode(new ConfigNode(field.Name));
                                    if (configNode.HasValue(field.Name))
                                    {
                                        configNode.RemoveValue(field.Name);
                                    }
                                }
                            }

                            if (isValueNode)
                            {
                                if ((newValue != defaultValue && value != newValue) || toggle)
                                {
                                    if (newValue != defaultValue)
                                    {
                                        if (node != null)
                                        {
                                            node.SetValue(valueField, newValue, true);
                                        }
                                        else
                                        {
                                            configNode.SetValue(field.Name, newValue, true);
                                        }
                                    }
                                    if (newValue == defaultValue)
                                    {
                                        if (node != null)
                                        {
                                            if (node.HasValue(valueField))
                                            {
                                                node.RemoveValue(valueField);
                                            }
                                        }
                                        else
                                        {
                                            if (configNode.HasValue(field.Name))
                                            {
                                                configNode.RemoveValue(field.Name);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else if (node == null)
                        {
                            node = configNode.AddNode(new ConfigNode(field.Name));
                        }
                        boxPlacement.y += 1f;
                        if (node != null)
                        {
                            object subObj = field.GetValue(obj);


                            if (subObj == null)
                            {
                                ConstructorInfo ctor = field.FieldType.GetConstructor(System.Type.EmptyTypes);
                                subObj = ctor.Invoke(null);
                            }

                            if (isList)
                            {
                                if (typeof(IList).IsAssignableFrom(field.FieldType))
                                {
                                    var itemNodes = node.GetNodes();

                                    bool isExpanded = IsListExpanded(configNode, field, meta.StartsCollapsed);
                                    if (GUI.Button(listCollapseRec, isExpanded ? "Click to collapse list" : "Click to expand list"))
                                    {
                                        isExpanded = !isExpanded;
                                        SetListExpanded(configNode, field, isExpanded);
                                    }

                                    if (GUI.Button(listPlusRec, "+"))
                                    {
                                        node.AddNode("Item");
                                    }

                                    if (GUI.Button(listMinusRec, "-"))
                                    {
                                        itemNodes = node.GetNodes();

                                        if (itemNodes.Length > 0)
                                        {
                                            node.RemoveNode(itemNodes[itemNodes.Length - 1]);
                                        }
                                    }

                                    if (isExpanded)
                                    {
                                        var itemList = subObj as IList;

                                        var innerType = GetCachedGenericArg(field.FieldType);

                                        while (itemList.Count < itemNodes.Length)
                                        {
                                            itemList.Add(Activator.CreateInstance(innerType));
                                        }

                                        while (itemList.Count > itemNodes.Length)
                                        {
                                            itemList.RemoveAt(itemList.Count - 1);
                                        }

                                        for (int i = 0; i < itemList.Count; i++)
                                        {
                                            var itemNode = itemNodes[i];

                                            HandleGUI(itemList[i], null, itemNode, boxPlacementBase, ref boxPlacement);

                                            if (i < itemList.Count - 1)
                                            {
                                                Rect separatorPlacement = new Rect(boxPlacement);
                                                separatorPlacement.y += 2f * spacingOffset;
                                                separatorPlacement.height = 1f / elementHeight;

                                                Rect separatorRect = GUIHelper.GetRect(boxPlacementBase, ref separatorPlacement);
                                                separatorRect.x += 10f;
                                                separatorRect.width -= 20f;
                                                separatorRect.height = 1f;

                                                Color previousColor = GUI.color;
                                                GUI.color = new Color(1f, 1f, 1f, 0.35f);
                                                GUI.DrawTexture(separatorRect, GetSeparatorTexture());
                                                GUI.color = previousColor;

                                                boxPlacement.y += 4 * spacingOffset;
                                            }
                                        }
                                    }
                                }
                            }
                            else
                            {
                                HandleGUI(subObj, field, node, boxPlacementBase, ref boxPlacement);
                            }

                        }
                        boxPlacement.y += spacingOffset;

                        placement.y = boxPlacement.y;
                        placement.x = boxPlacement.x;
                    }
                    else
                    {
                        if (configNode.HasNode(field.Name))
                        {
                            configNode.RemoveNode(field.Name);
                        }
                        if (configNode.HasValue(field.Name))
                        {
                            configNode.RemoveValue(field.Name);
                        }
                    }
                }
                else
                {
                    if (objInfo == null || ConfigHelper.ConditionsMet(field, objInfo, configNode))
                    {
                        // viewport culling: skip simple fields
                        float fieldAdvance;
                        if (meta.IsHidden)
                        {
                            fieldAdvance = 0f;
                        }
                        else if (field.FieldType == typeof(FloatCurve))
                        {
                            fieldAdvance = spacingOffset + GetFloatCurveHeight(configNode, field.Name);
                        }
                        else
                        {
                            fieldAdvance = spacingOffset + 1f;
                        }

                        if (fieldAdvance > 0f)
                        {
                            float topPx = placement.y * elementHeight + placementBase.y;
                            float bottomPx = topPx + fieldAdvance * elementHeight;
                            if (!IsRangeVisible(topPx, bottomPx))
                            {
                                placement.y += fieldAdvance;
                                continue;
                            }
                        }

                        GUIHelper.DrawField(placementBase, ref placement, obj, meta, configNode);
                    }
                    else if (configNode.HasValue(field.Name))
                    {
                        configNode.RemoveValue(field.Name);
                    }
                }
            }

        }

    }
}