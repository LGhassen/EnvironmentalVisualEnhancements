using System;
using System.Collections.Generic;
using UnityEngine;

namespace Utils
{
    // Immediate-mode curve editor for FloatCurve, built on GUI.* only
    public static class CurveEditor
    {
        private const int CURVE_TEX_WIDTH = 512;
        private const int CURVE_TEX_HEIGHT = 256;

        private const float HANDLE_RADIUS = 5f;
        private const float TANGENT_LENGTH = 40f;

        private static readonly Color CurveColor = new Color(0.2f, 0.8f, 0.4f);
        private static readonly Color GridColor = new Color(1f, 1f, 1f, 0.08f);
        private static readonly Color GridColorMajor = new Color(1f, 1f, 1f, 0.18f);
        private static readonly Color HandleColor = new Color(1f, 0.9f, 0.3f);
        private static readonly Color HandleSelected = new Color(1f, 0.45f, 0.1f);
        private static readonly Color TangentColor = new Color(0.6f, 0.6f, 1f, 0.7f);
        private static readonly Color BackgroundColor = new Color(0.12f, 0.12f, 0.14f);
        private static readonly Color AxisLabelColor = new Color(1f, 1f, 1f, 0.5f);
        private static readonly Color BorderColor = new Color(0.3f, 0.3f, 0.35f);

        private class EditorState
        {
            public Texture2D CurveTex;
            public int DirtyHash;
            public int SelectedKey = -1;
            public bool DraggingKey;
            public bool DraggingInTan;
            public bool DraggingOutTan;
            public float RangeMinT, RangeMaxT;
            public float RangeMinV, RangeMaxV;
            public bool ViewInitialized;
            public bool PanningView;
            public Vector2 PanLastMousePos;
            public bool ViewDirty;
        }
        private static readonly Dictionary<ConfigNode, EditorState> _states =
            new Dictionary<ConfigNode, EditorState>();

        private static Texture2D _whiteTex;
        private static Texture2D WhiteTex
        {
            get
            {
                if (_whiteTex == null)
                {
                    _whiteTex = new Texture2D(1, 1, TextureFormat.RGBA32, false);
                    _whiteTex.SetPixel(0, 0, Color.white);
                    _whiteTex.Apply();
                }
                return _whiteTex;
            }
        }

        public static void DrawCurveEditor(Rect rect, ConfigNode subNode)
        {
            if (subNode == null) return;

            if (!_states.TryGetValue(subNode, out var state))
            {
                state = new EditorState();
                _states[subNode] = state;
            }

            var curve = BuildCurve(subNode);
            int hash = ComputeHash(subNode);

            if (!state.ViewInitialized)
            {
                ComputeRanges(curve, state);
                state.ViewInitialized = true;
            }

            float toolbarH = 20f;
            float labelPadX = 36f;   // space for Y-axis labels
            float labelPadB = 16f;   // space for X-axis labels

            Rect toolbarRect = new Rect(rect.x, rect.y, rect.width, toolbarH);
            Rect curveArea = new Rect(rect.x + labelPadX,
                                        rect.y + toolbarH + 2f,
                                        rect.width - labelPadX - 4f,
                                        rect.height - toolbarH - labelPadB - 4f);

            // background
            DrawRect(rect, BackgroundColor);
            DrawRectOutline(rect, BorderColor);

            // toolbar
            DrawToolbar(toolbarRect, subNode, curve, state);

            // grid + axis labels
            DrawGrid(curveArea, state);
            DrawAxisLabels(curveArea, state, labelPadX, labelPadB);

            // curve texture
            if (state.CurveTex == null || hash != state.DirtyHash || state.ViewDirty)
            {
                state.CurveTex = RenderCurveTexture(curve, state);
                state.DirtyHash = hash;
                state.ViewDirty = false;
            }
            GUI.DrawTexture(curveArea, state.CurveTex);

            // keyframe handles + tangents
            DrawHandles(curveArea, subNode, curve, state);
        }

        private static void DrawToolbar(Rect r, ConfigNode node, AnimationCurve curve, EditorState state)
        {
            float bw = 22f;
            float spacing = 4f;
            float x = r.x + 2f;

            // [+] add key
            if (GUI.Button(new Rect(x, r.y, bw, r.height), "+"))
            {
                float t = (state.RangeMinT + state.RangeMaxT) * 0.5f;
                float v = curve.Evaluate(t);
                AddKey(node, t, v);
                state.SelectedKey = curve.length; // will be last
            }
            x += bw + spacing;

            // [-] remove selected key
            bool canRemove = state.SelectedKey >= 0 && state.SelectedKey < curve.length;
            if (GUI.Button(new Rect(x, r.y, bw, r.height), "\u2212") && canRemove)
            {
                RemoveKey(node, state.SelectedKey);
                state.SelectedKey = -1;
            }
            x += bw + spacing;

            // selected key info
            if (state.SelectedKey >= 0 && state.SelectedKey < curve.length)
            {
                var kf = curve[state.SelectedKey];
                string info = string.Format("Key {0}:  t={1:F3}  v={2:F3}  in={3:F3}  out={4:F3}",
                    state.SelectedKey, kf.time, kf.value, kf.inTangent, kf.outTangent);
                GUI.Label(new Rect(x, r.y, r.width - (x - r.x), r.height), info);
            }
            else
            {
                GUI.Label(new Rect(x, r.y, r.width - (x - r.x), r.height),
                    "Click to add | Drag handles | Right-click delete | Middle-clidk pan | Scroll zoom");
            }
        }

        private static void DrawGrid(Rect area, EditorState s)
        {
            float spanT = s.RangeMaxT - s.RangeMinT;
            float spanV = s.RangeMaxV - s.RangeMinV;
            if (spanT <= 0f || spanV <= 0f) return;

            float stepT = NiceStep(spanT, 6);
            float stepV = NiceStep(spanV, 5);

            // vertical lines (time axis)
            float t0 = Mathf.Ceil(s.RangeMinT / stepT) * stepT;
            for (float t = t0; t <= s.RangeMaxT; t += stepT)
            {
                float nx = (t - s.RangeMinT) / spanT;
                float px = area.x + nx * area.width;
                bool major = Mathf.Abs(t) < stepT * 0.01f;
                DrawLine(new Vector2(px, area.y),
                         new Vector2(px, area.yMax),
                         major ? GridColorMajor : GridColor);
            }
            // horizontal lines (value axis)
            float v0 = Mathf.Ceil(s.RangeMinV / stepV) * stepV;
            for (float v = v0; v <= s.RangeMaxV; v += stepV)
            {
                float ny = 1f - (v - s.RangeMinV) / spanV;
                float py = area.y + ny * area.height;
                bool major = Mathf.Abs(v) < stepV * 0.01f;
                DrawLine(new Vector2(area.x, py),
                         new Vector2(area.xMax, py),
                         major ? GridColorMajor : GridColor);
            }
        }

        private static void DrawAxisLabels(Rect area, EditorState s, float padX, float padB)
        {
            float spanT = s.RangeMaxT - s.RangeMinT;
            float spanV = s.RangeMaxV - s.RangeMinV;
            if (spanT <= 0f || spanV <= 0f) return;

            var labelStyle = new GUIStyle(GUI.skin.label)
            {
                fontSize = 9,
                alignment = TextAnchor.MiddleCenter,
                normal = { textColor = AxisLabelColor }
            };

            float stepT = NiceStep(spanT, 6);
            float stepV = NiceStep(spanV, 5);

            // X-axis
            float t0 = Mathf.Ceil(s.RangeMinT / stepT) * stepT;
            for (float t = t0; t <= s.RangeMaxT; t += stepT)
            {
                float nx = (t - s.RangeMinT) / spanT;
                float px = area.x + nx * area.width;
                Rect lr = new Rect(px - 20f, area.yMax + 1f, 40f, padB);
                GUI.Label(lr, t.ToString("G4"), labelStyle);
            }

            // Y-axis
            labelStyle.alignment = TextAnchor.MiddleRight;
            float v0 = Mathf.Ceil(s.RangeMinV / stepV) * stepV;
            for (float v = v0; v <= s.RangeMaxV; v += stepV)
            {
                float ny = 1f - (v - s.RangeMinV) / spanV;
                float py = area.y + ny * area.height;
                Rect lr = new Rect(area.x - padX, py - 8f, padX - 3f, 16f);
                GUI.Label(lr, v.ToString("G4"), labelStyle);
            }
        }

        private static Texture2D RenderCurveTexture(AnimationCurve curve, EditorState s)
        {
            var tex = new Texture2D(CURVE_TEX_WIDTH, CURVE_TEX_HEIGHT, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp
            };

            var pixels = new Color[CURVE_TEX_WIDTH * CURVE_TEX_HEIGHT];
            var clear = new Color(0, 0, 0, 0);
            for (int i = 0; i < pixels.Length; i++) pixels[i] = clear;

            float spanT = s.RangeMaxT - s.RangeMinT;
            float spanV = s.RangeMaxV - s.RangeMinV;

            if (curve.length >= 1 && spanT > 0f && spanV > 0f)
            {
                // evaluate curve at every pixel column and draw anti-aliased
                int prevPy = -1;
                for (int px = 0; px < CURVE_TEX_WIDTH; px++)
                {
                    float t = s.RangeMinT + (px / (float)(CURVE_TEX_WIDTH - 1)) * spanT;
                    float v = curve.Evaluate(t);
                    float ny = (v - s.RangeMinV) / spanV;           // 0..1 bottom-to-top
                    int py = Mathf.Clamp(Mathf.RoundToInt(ny * (CURVE_TEX_HEIGHT - 1)), 0, CURVE_TEX_HEIGHT - 1);

                    // vertical line-fill between prev and current for continuity
                    if (prevPy >= 0 && Mathf.Abs(py - prevPy) > 1)
                    {
                        int lo = Mathf.Min(py, prevPy);
                        int hi = Mathf.Max(py, prevPy);
                        for (int y = lo; y <= hi; y++)
                            PlotThick(pixels, px, y, CurveColor);
                    }
                    else
                    {
                        PlotThick(pixels, px, py, CurveColor);
                    }
                    prevPy = py;
                }
            }

            tex.SetPixels(pixels);
            tex.Apply();
            return tex;
        }

        private static void PlotThick(Color[] buf, int px, int py, Color c)
        {
            // 3-pixel wide curve for visibility
            for (int dy = -1; dy <= 1; dy++)
            {
                int y = py + dy;
                if (y < 0 || y >= CURVE_TEX_HEIGHT) continue;
                float alpha = dy == 0 ? 1f : 0.35f;
                int idx = y * CURVE_TEX_WIDTH + px;
                buf[idx] = Color.Lerp(buf[idx], c, alpha);
            }
        }

        private static void DrawHandles(Rect area, ConfigNode node, AnimationCurve curve, EditorState state)
        {
            Event e = Event.current;
            float spanT = state.RangeMaxT - state.RangeMinT;
            float spanV = state.RangeMaxV - state.RangeMinV;
            if (spanT <= 0f || spanV <= 0f) return;

            int controlID = GUIUtility.GetControlID(FocusType.Passive);

            // handle each keyframe
            for (int i = 0; i < curve.length; i++)
            {
                var kf = curve[i];
                Vector2 pos = KeyToPixel(kf.time, kf.value, area, state);
                bool selected = (i == state.SelectedKey);

                // tangent handles (only for selected key)
                if (selected)
                {
                    // in-tangent
                    Vector2 inEnd = TangentEndPoint(pos, kf.inTangent, -1f, area, state);
                    DrawLine(pos, inEnd, TangentColor);
                    DrawDisc(inEnd, HANDLE_RADIUS - 1f, TangentColor);

                    // out-tangent
                    Vector2 outEnd = TangentEndPoint(pos, kf.outTangent, 1f, area, state);
                    DrawLine(pos, outEnd, TangentColor);
                    DrawDisc(outEnd, HANDLE_RADIUS - 1f, TangentColor);

                    // tangent dragging
                    HandleTangentDrag(inEnd, outEnd, area, node, curve, i, state, e);
                }

                // keyframe disc
                DrawDisc(pos, HANDLE_RADIUS, selected ? HandleSelected : HandleColor);
            }

            // mouse interaction on the curve area
            if (e.type == EventType.MouseDown && area.Contains(e.mousePosition))
            {
                if (e.button == 2)
                {
                    // middle mouse => start panning
                    state.PanningView = true;
                    state.PanLastMousePos = e.mousePosition;
                    GUIUtility.hotControl = controlID;
                    e.Use();
                }
                else
                {
                    // check if clicking near a keyframe
                    int closest = -1;
                    float closestDist = HANDLE_RADIUS + 4f;
                    for (int i = 0; i < curve.length; i++)
                    {
                        Vector2 pos = KeyToPixel(curve[i].time, curve[i].value, area, state);
                        float d = Vector2.Distance(e.mousePosition, pos);
                        if (d < closestDist)
                        {
                            closestDist = d;
                            closest = i;
                        }
                    }

                    if (e.button == 0)
                    {
                        if (closest >= 0)
                        {
                            state.SelectedKey = closest;
                            state.DraggingKey = true;
                            GUIUtility.hotControl = controlID;
                            e.Use();
                        }
                        else
                        {
                            // click on empty area => add a new key
                            float t, v;
                            PixelToKey(e.mousePosition, area, state, out t, out v);
                            AddKey(node, t, v);
                            // rebuild and select the new key
                            curve = BuildCurve(node);
                            // find the key we just inserted
                            for (int i = 0; i < curve.length; i++)
                            {
                                if (Mathf.Abs(curve[i].time - t) < 0.0001f)
                                {
                                    state.SelectedKey = i;
                                    break;
                                }
                            }
                            state.DraggingKey = true;
                            GUIUtility.hotControl = controlID;
                            e.Use();
                        }
                    }
                    else if (e.button == 1 && closest >= 0)
                    {
                        // right-click => delete key
                        RemoveKey(node, closest);
                        if (state.SelectedKey == closest) state.SelectedKey = -1;
                        else if (state.SelectedKey > closest) state.SelectedKey--;
                        e.Use();
                    }
                }
            }
            else if (e.type == EventType.MouseDrag && state.DraggingKey &&
                     state.SelectedKey >= 0 && state.SelectedKey < curve.length)
            {
                float t, v;
                PixelToKey(e.mousePosition, area, state, out t, out v);
                MoveKey(node, curve, state.SelectedKey, t, v);
                e.Use();
            }
            else if (e.type == EventType.MouseDrag && state.PanningView)
            {
                Vector2 delta = e.mousePosition - state.PanLastMousePos;
                state.PanLastMousePos = e.mousePosition;
                // dragging right/down moves the curve in that direction (grab-and-drag)
                float deltaT = -delta.x * spanT / area.width;
                float deltaV =  delta.y * spanV / area.height;
                state.RangeMinT += deltaT;
                state.RangeMaxT += deltaT;
                state.RangeMinV += deltaV;
                state.RangeMaxV += deltaV;
                state.ViewDirty = true;
                e.Use();
            }
            else if (e.type == EventType.MouseUp)
            {
                if (state.DraggingKey || state.DraggingInTan || state.DraggingOutTan)
                {
                    state.DraggingKey = false;
                    state.DraggingInTan = false;
                    state.DraggingOutTan = false;
                    if (GUIUtility.hotControl == controlID)
                        GUIUtility.hotControl = 0;
                    e.Use();
                }
                else if (state.PanningView)
                {
                    state.PanningView = false;
                    if (GUIUtility.hotControl == controlID)
                        GUIUtility.hotControl = 0;
                    e.Use();
                }
            }

            // scroll wheel zoom (zooms toward the mouse cursor position)
            if (e.type == EventType.ScrollWheel && area.Contains(e.mousePosition))
            {
                float zoomFactor = 1f + e.delta.y * 0.1f;
                zoomFactor = Mathf.Clamp(zoomFactor, 0.05f, 20f);
                float mouseT, mouseV;
                PixelToKey(e.mousePosition, area, state, out mouseT, out mouseV);
                state.RangeMinT = mouseT - (mouseT - state.RangeMinT) * zoomFactor;
                state.RangeMaxT = mouseT + (state.RangeMaxT - mouseT) * zoomFactor;
                state.RangeMinV = mouseV - (mouseV - state.RangeMinV) * zoomFactor;
                state.RangeMaxV = mouseV + (state.RangeMaxV - mouseV) * zoomFactor;
                state.ViewDirty = true;
                e.Use();
            }
        }

        private static void HandleTangentDrag(Vector2 inEnd, Vector2 outEnd,
            Rect area, ConfigNode node, AnimationCurve curve, int keyIdx,
            EditorState state, Event e)
        {
            int controlID = GUIUtility.GetControlID(FocusType.Passive);

            if (e.type == EventType.MouseDown && e.button == 0)
            {
                if (Vector2.Distance(e.mousePosition, inEnd) < HANDLE_RADIUS + 3f)
                {
                    state.DraggingInTan = true;
                    GUIUtility.hotControl = controlID;
                    e.Use();
                }
                else if (Vector2.Distance(e.mousePosition, outEnd) < HANDLE_RADIUS + 3f)
                {
                    state.DraggingOutTan = true;
                    GUIUtility.hotControl = controlID;
                    e.Use();
                }
            }
            else if (e.type == EventType.MouseDrag)
            {
                if (state.DraggingInTan || state.DraggingOutTan)
                {
                    var kf = curve[keyIdx];
                    Vector2 keyPos = KeyToPixel(kf.time, kf.value, area, state);
                    Vector2 delta = e.mousePosition - keyPos;

                    // tangent = dv/dt in data space, but screen Y is inverted
                    float spanT = state.RangeMaxT - state.RangeMinT;
                    float spanV = state.RangeMaxV - state.RangeMinV;
                    float dtPx = delta.x;
                    float dvPx = -delta.y;  // screen Y is flipped

                    float tangent;
                    if (Mathf.Abs(dtPx) < 1f)
                        tangent = dvPx >= 0 ? 1000f : -1000f;
                    else
                        tangent = (dvPx / dtPx) * (spanT / spanV) * (area.height / area.width);

                    // for in-tangent the handle is to the left so flip sign reference
                    if (state.DraggingInTan)
                        tangent = -((-delta.x > 0 ? 1f : -1f) * Mathf.Abs(tangent));

                    SetTangent(node, curve, keyIdx, state.DraggingInTan, tangent);
                    e.Use();
                }
            }
        }

        private static Vector2 KeyToPixel(float t, float v, Rect area, EditorState s)
        {
            float nx = (t - s.RangeMinT) / (s.RangeMaxT - s.RangeMinT);
            float ny = (v - s.RangeMinV) / (s.RangeMaxV - s.RangeMinV);
            return new Vector2(area.x + nx * area.width,
                               area.yMax - ny * area.height);
        }

        private static void PixelToKey(Vector2 px, Rect area, EditorState s, out float t, out float v)
        {
            float nx = (px.x - area.x) / area.width;
            float ny = (area.yMax - px.y) / area.height;
            t = s.RangeMinT + nx * (s.RangeMaxT - s.RangeMinT);
            v = s.RangeMinV + ny * (s.RangeMaxV - s.RangeMinV);
        }

        private static Vector2 TangentEndPoint(Vector2 keyPx, float tangent, float dir,
                                                Rect area, EditorState s)
        {
            // dir: -1 for in-tangent (left), +1 for out-tangent (right)
            float spanT = s.RangeMaxT - s.RangeMinT;
            float spanV = s.RangeMaxV - s.RangeMinV;

            // tangent is dv/dt in data space; convert to pixels
            float dx = dir * TANGENT_LENGTH;
            float dy = -tangent * dx * (spanV / spanT) * (area.width / area.height);

            // clamp length
            Vector2 d = new Vector2(dx, dy);
            if (d.magnitude > TANGENT_LENGTH)
                d = d.normalized * TANGENT_LENGTH;

            return keyPx + d;
        }

        private static AnimationCurve BuildCurve(ConfigNode node)
        {
            var curve = new AnimationCurve();
            foreach (string val in node.GetValuesStartsWith("key"))
            {
                string[] parts = val.Split(new[] { ' ', '\t' },
                    StringSplitOptions.RemoveEmptyEntries);

                if (parts.Length >= 2)
                {
                    float time, value;
                    if (!float.TryParse(parts[0], out time) ||
                        !float.TryParse(parts[1], out value)) continue;

                    if (parts.Length >= 4)
                    {
                        float inT, outT;
                        float.TryParse(parts[2], out inT);
                        float.TryParse(parts[3], out outT);
                        curve.AddKey(new Keyframe(time, value, inT, outT));
                    }
                    else
                    {
                        curve.AddKey(new Keyframe(time, value));
                    }
                }
            }
            return curve;
        }

        private static void WriteCurveToNode(ConfigNode node, AnimationCurve curve)
        {
            node.ClearValues();
            for (int i = 0; i < curve.length; i++)
            {
                var kf = curve[i];
                node.AddValue("key",
                    string.Format("{0} {1} {2} {3}",
                        kf.time, kf.value, kf.inTangent, kf.outTangent));
            }
        }

        private static void AddKey(ConfigNode node, float t, float v)
        {
            var curve = BuildCurve(node);
            curve.AddKey(new Keyframe(t, v));
            WriteCurveToNode(node, curve);
        }

        private static void RemoveKey(ConfigNode node, int index)
        {
            var curve = BuildCurve(node);
            if (index >= 0 && index < curve.length)
            {
                curve.RemoveKey(index);
                WriteCurveToNode(node, curve);
            }
        }

        private static void MoveKey(ConfigNode node, AnimationCurve curve, int index, float t, float v)
        {
            if (index < 0 || index >= curve.length) return;
            var kf = curve[index];
            kf.time = t;
            kf.value = v;
            curve.MoveKey(index, kf);
            WriteCurveToNode(node, curve);
        }

        private static void SetTangent(ConfigNode node, AnimationCurve curve, int index,
                                        bool isIn, float tangent)
        {
            if (index < 0 || index >= curve.length) return;
            var kf = curve[index];
            if (isIn) kf.inTangent = tangent;
            else kf.outTangent = tangent;
            curve.MoveKey(index, kf);
            WriteCurveToNode(node, curve);
        }

        private static void ComputeRanges(AnimationCurve curve, EditorState s)
        {
            if (curve.length == 0)
            {
                s.RangeMinT = 0f; s.RangeMaxT = 1f;
                s.RangeMinV = 0f; s.RangeMaxV = 1f;
                return;
            }

            float tMin = curve[0].time;
            float tMax = curve[curve.length - 1].time;
            float vMin = float.MaxValue;
            float vMax = float.MinValue;

            // sample the curve densely for value extremes
            int samples = Mathf.Max(curve.length * 20, 100);
            for (int i = 0; i <= samples; i++)
            {
                float t = Mathf.Lerp(tMin, tMax, i / (float)samples);
                float v = curve.Evaluate(t);
                vMin = Mathf.Min(vMin, v);
                vMax = Mathf.Max(vMax, v);
            }
            // also check actual keyframe values
            for (int i = 0; i < curve.length; i++)
            {
                vMin = Mathf.Min(vMin, curve[i].value);
                vMax = Mathf.Max(vMax, curve[i].value);
            }

            // padding
            float tPad = Mathf.Max((tMax - tMin) * 0.08f, 0.1f);
            float vPad = Mathf.Max((vMax - vMin) * 0.12f, 0.1f);

            s.RangeMinT = tMin - tPad;
            s.RangeMaxT = tMax + tPad;
            s.RangeMinV = vMin - vPad;
            s.RangeMaxV = vMax + vPad;
        }

        private static void DrawRect(Rect r, Color c)
        {
            Color old = GUI.color;
            GUI.color = c;
            GUI.DrawTexture(r, WhiteTex);
            GUI.color = old;
        }

        private static void DrawRectOutline(Rect r, Color c)
        {
            DrawRect(new Rect(r.x, r.y, r.width, 1), c);
            DrawRect(new Rect(r.x, r.yMax - 1, r.width, 1), c);
            DrawRect(new Rect(r.x, r.y, 1, r.height), c);
            DrawRect(new Rect(r.xMax - 1, r.y, 1, r.height), c);
        }

        private static void DrawDisc(Vector2 center, float radius, Color c)
        {
            DrawRect(new Rect(center.x - radius, center.y - radius,
                              radius * 2, radius * 2), c);
        }

        private static void DrawLine(Vector2 a, Vector2 b, Color c)
        {
            // Bresenham-ish thick line via small rects (works in IMGUI)
            float dist = Vector2.Distance(a, b);
            int steps = Mathf.Max(Mathf.CeilToInt(dist / 2f), 1);
            float thickness = 1f;
            Color old = GUI.color;
            GUI.color = c;
            for (int i = 0; i <= steps; i++)
            {
                float frac = i / (float)steps;
                Vector2 p = Vector2.Lerp(a, b, frac);
                GUI.DrawTexture(new Rect(p.x - thickness * 0.5f, p.y - thickness * 0.5f,
                                         thickness, thickness), WhiteTex);
            }
            GUI.color = old;
        }

        private static int ComputeHash(ConfigNode node)
        {
            unchecked
            {
                int h = 17;
                foreach (string v in node.GetValuesStartsWith("key"))
                    h = h * 31 + v.GetHashCode();
                return h;
            }
        }

        private static float NiceStep(float span, int targetLines)
        {
            float raw = span / targetLines;
            float mag = Mathf.Pow(10f, Mathf.Floor(Mathf.Log10(raw)));
            float norm = raw / mag;
            float nice;
            if (norm < 1.5f) nice = 1f;
            else if (norm < 3.5f) nice = 2f;
            else if (norm < 7.5f) nice = 5f;
            else nice = 10f;
            return nice * mag;
        }
    }
}
