using System;
using System.Collections.Generic;
using UnityEngine;

namespace Utils
{
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
        private static readonly Color HandleSelectedColor = new Color(1f, 0.45f, 0.1f);
        private static readonly Color TangentColor = new Color(0.6f, 0.6f, 1f, 0.7f);
        private static readonly Color BackgroundColor = new Color(0.12f, 0.12f, 0.14f);
        private static readonly Color AxisLabelColor = new Color(1f, 1f, 1f, 0.5f);
        private static readonly Color BorderColor = new Color(0.3f, 0.3f, 0.35f);

        private class EditorState
        {
            public Texture2D curveTex;
            public Texture2D gridTex;
            public AnimationCurve cachedCurve;
            public int dirtyHash;
            public int selectedKey = -1;
            public bool draggingKey;
            public bool draggingInTangent;
            public bool draggingOutTangent;
            public float rangeMinTime, rangeMaxTime;
            public float rangeMinValue, rangeMaxValue;
            public bool viewInitialized;
            public bool panningView;
            public Vector2 panLastMousePos;
            public bool viewDirty;
        }

        private static readonly Dictionary<ConfigNode, EditorState> states =
            new Dictionary<ConfigNode, EditorState>();

        private static Texture2D whiteTex;
        private static Texture2D WhiteTex
        {
            get
            {
                if (whiteTex == null)
                {
                    whiteTex = new Texture2D(1, 1, TextureFormat.RGBA32, false);
                    whiteTex.SetPixel(0, 0, Color.white);
                    whiteTex.Apply();
                }
                return whiteTex;
            }
        }

        private static GUIStyle axisLabelStyle;

        public static void DrawCurveEditor(Rect rect, ConfigNode subNode)
        {
            if (subNode == null) return;

            if (!states.TryGetValue(subNode, out var state))
            {
                state = new EditorState();
                states[subNode] = state;
            }

            int hash = ComputeHash(subNode);
            if (state.cachedCurve == null || hash != state.dirtyHash)
                state.cachedCurve = BuildCurve(subNode);
            var curve = state.cachedCurve;

            if (!state.viewInitialized)
            {
                ComputeRanges(curve, state);
                state.viewInitialized = true;
            }

            float toolbarHeight = 20f;
            float yAxisLabelWidth = 36f;
            float xAxisLabelHeight = 16f;

            Rect toolbarRect = new Rect(rect.x, rect.y, rect.width, toolbarHeight);
            Rect curveArea = new Rect(
                rect.x + yAxisLabelWidth,
                rect.y + toolbarHeight + 2f,
                rect.width - yAxisLabelWidth - 4f,
                rect.height - toolbarHeight - xAxisLabelHeight - 4f);

            DrawRect(rect, BackgroundColor);
            DrawRectOutline(rect, BorderColor);
            DrawToolbar(toolbarRect, subNode, curve, state);

            if (state.curveTex == null || hash != state.dirtyHash || state.viewDirty)
            {
                state.gridTex = RenderGridTexture(state);
                state.curveTex = RenderCurveTexture(curve, state);
                state.dirtyHash = hash;
                state.viewDirty = false;
            }

            GUI.DrawTexture(curveArea, state.gridTex);
            GUI.DrawTexture(curveArea, state.curveTex);

            DrawAxisLabels(curveArea, state, yAxisLabelWidth, xAxisLabelHeight);
            DrawHandles(curveArea, subNode, curve, state);
        }

        private static void DrawToolbar(Rect toolbarRect, ConfigNode node, AnimationCurve curve, EditorState state)
        {
            float buttonWidth = 22f;
            float spacing = 4f;
            float currentX = toolbarRect.x + 2f;

            if (GUI.Button(new Rect(currentX, toolbarRect.y, buttonWidth, toolbarRect.height), "+"))
            {
                float midTime = (state.rangeMinTime + state.rangeMaxTime) * 0.5f;
                float midValue = curve.Evaluate(midTime);
                AddKey(node, midTime, midValue);
                state.selectedKey = curve.length;
            }
            currentX += buttonWidth + spacing;

            bool canRemove = state.selectedKey >= 0 && state.selectedKey < curve.length;
            if (GUI.Button(new Rect(currentX, toolbarRect.y, buttonWidth, toolbarRect.height), "\u2212") && canRemove)
            {
                RemoveKey(node, state.selectedKey);
                state.selectedKey = -1;
            }
            currentX += buttonWidth + spacing;

            float remainingWidth = toolbarRect.width - (currentX - toolbarRect.x);
            Rect labelRect = new Rect(currentX, toolbarRect.y, remainingWidth, toolbarRect.height);

            if (state.selectedKey >= 0 && state.selectedKey < curve.length)
            {
                var keyframe = curve[state.selectedKey];
                string info = string.Format("Key {0}:  t={1:F3}  v={2:F3}  in={3:F3}  out={4:F3}",
                    state.selectedKey, keyframe.time, keyframe.value, keyframe.inTangent, keyframe.outTangent);
                GUI.Label(labelRect, info);
            }
            else
            {
                GUI.Label(labelRect, "Click to add | Drag handles | Right-click delete | Middle-click pan | Scroll zoom");
            }
        }

        private static Texture2D RenderGridTexture(EditorState state)
        {
            var tex = new Texture2D(CURVE_TEX_WIDTH, CURVE_TEX_HEIGHT, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp
            };

            var pixels = new Color[CURVE_TEX_WIDTH * CURVE_TEX_HEIGHT];

            float timeSpan = state.rangeMaxTime - state.rangeMinTime;
            float valueSpan = state.rangeMaxValue - state.rangeMinValue;

            if (timeSpan <= 0f || valueSpan <= 0f)
            {
                tex.SetPixels(pixels);
                tex.Apply();
                return tex;
            }

            float timeStep = NiceStep(timeSpan, 6);
            float valueStep = NiceStep(valueSpan, 5);

            float firstTimeLine = Mathf.Ceil(state.rangeMinTime / timeStep) * timeStep;
            for (float time = firstTimeLine; time <= state.rangeMaxTime; time += timeStep)
            {
                float normalizedX = (time - state.rangeMinTime) / timeSpan;
                int pixelX = Mathf.Clamp(Mathf.RoundToInt(normalizedX * (CURVE_TEX_WIDTH - 1)), 0, CURVE_TEX_WIDTH - 1);
                bool isOrigin = Mathf.Abs(time) < timeStep * 0.01f;
                Color lineColor = isOrigin ? GridColorMajor : GridColor;
                for (int y = 0; y < CURVE_TEX_HEIGHT; y++)
                    pixels[y * CURVE_TEX_WIDTH + pixelX] = lineColor;
            }

            float firstValueLine = Mathf.Ceil(state.rangeMinValue / valueStep) * valueStep;
            for (float value = firstValueLine; value <= state.rangeMaxValue; value += valueStep)
            {
                float normalizedY = 1f - (value - state.rangeMinValue) / valueSpan;
                int pixelY = Mathf.Clamp(Mathf.RoundToInt(normalizedY * (CURVE_TEX_HEIGHT - 1)), 0, CURVE_TEX_HEIGHT - 1);
                bool isOrigin = Mathf.Abs(value) < valueStep * 0.01f;
                Color lineColor = isOrigin ? GridColorMajor : GridColor;
                for (int x = 0; x < CURVE_TEX_WIDTH; x++)
                    pixels[pixelY * CURVE_TEX_WIDTH + x] = lineColor;
            }

            tex.SetPixels(pixels);
            tex.Apply();
            return tex;
        }

        private static void DrawAxisLabels(Rect area, EditorState state, float yAxisLabelWidth, float xAxisLabelHeight)
        {
            float timeSpan = state.rangeMaxTime - state.rangeMinTime;
            float valueSpan = state.rangeMaxValue - state.rangeMinValue;
            if (timeSpan <= 0f || valueSpan <= 0f) return;

            if (axisLabelStyle == null)
            {
                axisLabelStyle = new GUIStyle(GUI.skin.label)
                {
                    fontSize = 9,
                    normal = { textColor = AxisLabelColor }
                };
            }

            float timeStep = NiceStep(timeSpan, 6);
            float valueStep = NiceStep(valueSpan, 5);

            axisLabelStyle.alignment = TextAnchor.MiddleCenter;
            float firstTimeLine = Mathf.Ceil(state.rangeMinTime / timeStep) * timeStep;
            for (float time = firstTimeLine; time <= state.rangeMaxTime; time += timeStep)
            {
                float normalizedX = (time - state.rangeMinTime) / timeSpan;
                float pixelX = area.x + normalizedX * area.width;
                Rect labelRect = new Rect(pixelX - 20f, area.yMax + 1f, 40f, xAxisLabelHeight);
                GUI.Label(labelRect, time.ToString("G4"), axisLabelStyle);
            }

            axisLabelStyle.alignment = TextAnchor.MiddleRight;
            float firstValueLine = Mathf.Ceil(state.rangeMinValue / valueStep) * valueStep;
            for (float value = firstValueLine; value <= state.rangeMaxValue; value += valueStep)
            {
                float normalizedY = 1f - (value - state.rangeMinValue) / valueSpan;
                float pixelY = area.y + normalizedY * area.height;
                Rect labelRect = new Rect(area.x - yAxisLabelWidth, pixelY - 8f, yAxisLabelWidth - 3f, 16f);
                GUI.Label(labelRect, value.ToString("G4"), axisLabelStyle);
            }
        }

        private static Texture2D RenderCurveTexture(AnimationCurve curve, EditorState state)
        {
            // TODO: reuse the texture instead of reallocating every time
            var tex = new Texture2D(CURVE_TEX_WIDTH, CURVE_TEX_HEIGHT, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp
            };

            var pixels = new Color[CURVE_TEX_WIDTH * CURVE_TEX_HEIGHT];
            var clear = new Color(0, 0, 0, 0);
            for (int i = 0; i < pixels.Length; i++) pixels[i] = clear;

            float timeSpan = state.rangeMaxTime - state.rangeMinTime;
            float valueSpan = state.rangeMaxValue - state.rangeMinValue;

            if (curve.length >= 1 && timeSpan > 0f && valueSpan > 0f)
            {
                int previousPixelY = -1;
                for (int pixelX = 0; pixelX < CURVE_TEX_WIDTH; pixelX++)
                {
                    float columnFraction = pixelX / (float)(CURVE_TEX_WIDTH - 1);
                    float time = state.rangeMinTime + columnFraction * timeSpan;
                    float value = curve.Evaluate(time);

                    float normalizedY = (value - state.rangeMinValue) / valueSpan;
                    int pixelY = Mathf.Clamp(Mathf.RoundToInt(normalizedY * (CURVE_TEX_HEIGHT - 1)), 0, CURVE_TEX_HEIGHT - 1);

                    bool hasGap = previousPixelY >= 0 && Mathf.Abs(pixelY - previousPixelY) > 1;
                    if (hasGap)
                    {
                        int lo = Mathf.Min(pixelY, previousPixelY);
                        int hi = Mathf.Max(pixelY, previousPixelY);
                        for (int y = lo; y <= hi; y++)
                            PlotThick(pixels, pixelX, y, CurveColor);
                    }
                    else
                    {
                        PlotThick(pixels, pixelX, pixelY, CurveColor);
                    }
                    previousPixelY = pixelY;
                }
            }

            tex.SetPixels(pixels);
            tex.Apply();
            return tex;
        }

        private static void PlotThick(Color[] buffer, int pixelX, int pixelY, Color color)
        {
            for (int offsetY = -1; offsetY <= 1; offsetY++)
            {
                int y = pixelY + offsetY;
                if (y < 0 || y >= CURVE_TEX_HEIGHT) continue;
                float alpha = offsetY == 0 ? 1f : 0.35f;
                int index = y * CURVE_TEX_WIDTH + pixelX;
                buffer[index] = Color.Lerp(buffer[index], color, alpha);
            }
        }

        private static void DrawHandles(Rect area, ConfigNode node, AnimationCurve curve, EditorState state)
        {
            Event currentEvent = Event.current;
            float timeSpan = state.rangeMaxTime - state.rangeMinTime;
            float valueSpan = state.rangeMaxValue - state.rangeMinValue;
            if (timeSpan <= 0f || valueSpan <= 0f) return;

            int controlID = GUIUtility.GetControlID(FocusType.Passive);

            for (int i = 0; i < curve.length; i++)
            {
                var keyframe = curve[i];
                Vector2 handlePos = KeyToPixel(keyframe.time, keyframe.value, area, state);
                bool isSelected = (i == state.selectedKey);
                bool isVisible = area.Contains(handlePos);

                if (isSelected)
                {
                    Vector2 inTangentEnd = ComputeTangentEndPoint(handlePos, keyframe.inTangent, -1f, area, state);
                    Vector2 outTangentEnd = ComputeTangentEndPoint(handlePos, keyframe.outTangent, 1f, area, state);

                    if (isVisible && area.Contains(inTangentEnd))
                    {
                        DrawLine(handlePos, inTangentEnd, TangentColor);
                        DrawDisc(inTangentEnd, HANDLE_RADIUS - 1f, TangentColor);
                    }

                    if (isVisible && area.Contains(outTangentEnd))
                    {
                        DrawLine(handlePos, outTangentEnd, TangentColor);
                        DrawDisc(outTangentEnd, HANDLE_RADIUS - 1f, TangentColor);
                    }

                    HandleTangentDrag(inTangentEnd, outTangentEnd, area, node, curve, i, state, currentEvent);
                }

                if (isVisible)
                    DrawDisc(handlePos, HANDLE_RADIUS, isSelected ? HandleSelectedColor : HandleColor);
            }

            HandleMouseInteraction(area, node, curve, state, currentEvent, controlID);
        }

        private static void HandleMouseInteraction(Rect area, ConfigNode node, AnimationCurve curve,
            EditorState state, Event currentEvent, int controlID)
        {
            float timeSpan = state.rangeMaxTime - state.rangeMinTime;
            float valueSpan = state.rangeMaxValue - state.rangeMinValue;

            if (currentEvent.type == EventType.MouseDown && area.Contains(currentEvent.mousePosition))
            {
                if (currentEvent.button == 2)
                {
                    state.panningView = true;
                    state.panLastMousePos = currentEvent.mousePosition;
                    GUIUtility.hotControl = controlID;
                    currentEvent.Use();
                }
                else
                {
                    int closestKey = FindClosestKeyframe(curve, currentEvent.mousePosition, area, state);

                    if (currentEvent.button == 0)
                    {
                        if (closestKey >= 0)
                        {
                            state.selectedKey = closestKey;
                            state.draggingKey = true;
                            GUIUtility.hotControl = controlID;
                            currentEvent.Use();
                        }
                        else
                        {
                            float time, value;
                            PixelToKey(currentEvent.mousePosition, area, state, out time, out value);
                            AddKey(node, time, value);

                            curve = BuildCurve(node);
                            for (int i = 0; i < curve.length; i++)
                            {
                                if (Mathf.Abs(curve[i].time - time) < 0.0001f)
                                {
                                    state.selectedKey = i;
                                    break;
                                }
                            }
                            state.draggingKey = true;
                            GUIUtility.hotControl = controlID;
                            currentEvent.Use();
                        }
                    }
                    else if (currentEvent.button == 1 && closestKey >= 0)
                    {
                        RemoveKey(node, closestKey);
                        if (state.selectedKey == closestKey) state.selectedKey = -1;
                        else if (state.selectedKey > closestKey) state.selectedKey--;
                        currentEvent.Use();
                    }
                }
            }
            else if (currentEvent.type == EventType.MouseDrag && state.draggingKey &&
                     state.selectedKey >= 0 && state.selectedKey < curve.length)
            {
                float time, value;
                PixelToKey(currentEvent.mousePosition, area, state, out time, out value);
                MoveKey(node, curve, state.selectedKey, time, value);
                currentEvent.Use();
            }
            else if (currentEvent.type == EventType.MouseDrag && state.panningView)
            {
                Vector2 mouseDelta = currentEvent.mousePosition - state.panLastMousePos;
                state.panLastMousePos = currentEvent.mousePosition;

                float panDeltaTime = -mouseDelta.x * timeSpan / area.width;
                float panDeltaValue = mouseDelta.y * valueSpan / area.height;
                state.rangeMinTime += panDeltaTime;
                state.rangeMaxTime += panDeltaTime;
                state.rangeMinValue += panDeltaValue;
                state.rangeMaxValue += panDeltaValue;
                state.viewDirty = true;
                currentEvent.Use();
            }
            else if (currentEvent.type == EventType.MouseUp)
            {
                bool wasDragging = state.draggingKey || state.draggingInTangent || state.draggingOutTangent;
                if (wasDragging)
                {
                    state.draggingKey = false;
                    state.draggingInTangent = false;
                    state.draggingOutTangent = false;
                    if (GUIUtility.hotControl == controlID)
                        GUIUtility.hotControl = 0;
                    currentEvent.Use();
                }
                else if (state.panningView)
                {
                    state.panningView = false;
                    if (GUIUtility.hotControl == controlID)
                        GUIUtility.hotControl = 0;
                    currentEvent.Use();
                }
            }

            if (currentEvent.type == EventType.ScrollWheel && area.Contains(currentEvent.mousePosition))
            {
                float zoomFactor = Mathf.Clamp(1f + currentEvent.delta.y * 0.1f, 0.05f, 20f);

                float mouseTime, mouseValue;
                PixelToKey(currentEvent.mousePosition, area, state, out mouseTime, out mouseValue);

                float distToMinTime = mouseTime - state.rangeMinTime;
                float distToMaxTime = state.rangeMaxTime - mouseTime;
                float distToMinValue = mouseValue - state.rangeMinValue;
                float distToMaxValue = state.rangeMaxValue - mouseValue;

                state.rangeMinTime = mouseTime - distToMinTime * zoomFactor;
                state.rangeMaxTime = mouseTime + distToMaxTime * zoomFactor;
                state.rangeMinValue = mouseValue - distToMinValue * zoomFactor;
                state.rangeMaxValue = mouseValue + distToMaxValue * zoomFactor;
                state.viewDirty = true;
                currentEvent.Use();
            }
        }

        private static int FindClosestKeyframe(AnimationCurve curve, Vector2 mousePos, Rect area, EditorState state)
        {
            int closestIndex = -1;
            float closestDistance = HANDLE_RADIUS + 4f;
            for (int i = 0; i < curve.length; i++)
            {
                Vector2 keyPos = KeyToPixel(curve[i].time, curve[i].value, area, state);
                float distance = Vector2.Distance(mousePos, keyPos);
                if (distance < closestDistance)
                {
                    closestDistance = distance;
                    closestIndex = i;
                }
            }
            return closestIndex;
        }

        private static void HandleTangentDrag(Vector2 inTangentEnd, Vector2 outTangentEnd,
            Rect area, ConfigNode node, AnimationCurve curve, int keyIndex,
            EditorState state, Event currentEvent)
        {
            int controlID = GUIUtility.GetControlID(FocusType.Passive);

            if (currentEvent.type == EventType.MouseDown && currentEvent.button == 0)
            {
                float distanceToIn = Vector2.Distance(currentEvent.mousePosition, inTangentEnd);
                float distanceToOut = Vector2.Distance(currentEvent.mousePosition, outTangentEnd);
                float hitRadius = HANDLE_RADIUS + 3f;

                if (distanceToIn < hitRadius)
                {
                    state.draggingInTangent = true;
                    GUIUtility.hotControl = controlID;
                    currentEvent.Use();
                }
                else if (distanceToOut < hitRadius)
                {
                    state.draggingOutTangent = true;
                    GUIUtility.hotControl = controlID;
                    currentEvent.Use();
                }
            }
            else if (currentEvent.type == EventType.MouseDrag)
            {
                if (state.draggingInTangent || state.draggingOutTangent)
                {
                    var keyframe = curve[keyIndex];
                    Vector2 keyPixelPos = KeyToPixel(keyframe.time, keyframe.value, area, state);
                    Vector2 mouseOffset = currentEvent.mousePosition - keyPixelPos;

                    float timeSpan = state.rangeMaxTime - state.rangeMinTime;
                    float valueSpan = state.rangeMaxValue - state.rangeMinValue;
                    float deltaTimePixels = mouseOffset.x;
                    float deltaValuePixels = -mouseOffset.y;

                    float tangent;
                    if (Mathf.Abs(deltaTimePixels) < 1f)
                    {
                        tangent = deltaValuePixels >= 0 ? 1000f : -1000f;
                    }
                    else
                    {
                        float pixelSlope = deltaValuePixels / deltaTimePixels;
                        float aspectCorrection = (timeSpan / valueSpan) * (area.height / area.width);
                        tangent = pixelSlope * aspectCorrection;
                    }

                    // The in-tangent handle extends to the left, so the sign must account for the direction
                    if (state.draggingInTangent)
                    {
                        float directionSign = -mouseOffset.x > 0 ? 1f : -1f;
                        tangent = -(directionSign * Mathf.Abs(tangent));
                    }

                    SetTangent(node, curve, keyIndex, state.draggingInTangent, tangent);
                    currentEvent.Use();
                }
            }
        }

        private static Vector2 KeyToPixel(float time, float value, Rect area, EditorState state)
        {
            float normalizedX = (time - state.rangeMinTime) / (state.rangeMaxTime - state.rangeMinTime);
            float normalizedY = (value - state.rangeMinValue) / (state.rangeMaxValue - state.rangeMinValue);
            return new Vector2(
                area.x + normalizedX * area.width,
                area.yMax - normalizedY * area.height);
        }

        private static void PixelToKey(Vector2 pixel, Rect area, EditorState state, out float time, out float value)
        {
            float normalizedX = (pixel.x - area.x) / area.width;
            float normalizedY = (area.yMax - pixel.y) / area.height;
            time = state.rangeMinTime + normalizedX * (state.rangeMaxTime - state.rangeMinTime);
            value = state.rangeMinValue + normalizedY * (state.rangeMaxValue - state.rangeMinValue);
        }

        private static Vector2 ComputeTangentEndPoint(Vector2 keyPixelPos, float tangent, float direction,
                                                       Rect area, EditorState state)
        {
            float timeSpan = state.rangeMaxTime - state.rangeMinTime;
            float valueSpan = state.rangeMaxValue - state.rangeMinValue;

            float deltaX = direction * TANGENT_LENGTH;
            float slopeScale = (valueSpan / timeSpan) * (area.width / area.height);
            float deltaY = -tangent * deltaX * slopeScale;

            Vector2 offset = new Vector2(deltaX, deltaY);
            if (offset.magnitude > TANGENT_LENGTH)
                offset = offset.normalized * TANGENT_LENGTH;

            return keyPixelPos + offset;
        }

        private static AnimationCurve BuildCurve(ConfigNode node)
        {
            var curve = new AnimationCurve();
            foreach (string val in node.GetValuesStartsWith("key"))
            {
                string[] parts = val.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);

                if (parts.Length < 2) continue;

                float time, value;
                if (!float.TryParse(parts[0], out time) ||
                    !float.TryParse(parts[1], out value)) continue;

                if (parts.Length >= 4)
                {
                    float inTangent, outTangent;
                    float.TryParse(parts[2], out inTangent);
                    float.TryParse(parts[3], out outTangent);
                    curve.AddKey(new Keyframe(time, value, inTangent, outTangent));
                }
                else
                {
                    curve.AddKey(new Keyframe(time, value));
                }
            }
            return curve;
        }

        private static void WriteCurveToNode(ConfigNode node, AnimationCurve curve)
        {
            node.ClearValues();
            for (int i = 0; i < curve.length; i++)
            {
                var keyframe = curve[i];
                node.AddValue("key",
                    string.Format("{0} {1} {2} {3}",
                        keyframe.time, keyframe.value, keyframe.inTangent, keyframe.outTangent));
            }
        }

        private static void AddKey(ConfigNode node, float time, float value)
        {
            var curve = BuildCurve(node);
            curve.AddKey(new Keyframe(time, value));
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

        private static void MoveKey(ConfigNode node, AnimationCurve curve, int index, float time, float value)
        {
            if (index < 0 || index >= curve.length) return;
            var keyframe = curve[index];
            keyframe.time = time;
            keyframe.value = value;
            curve.MoveKey(index, keyframe);
            WriteCurveToNode(node, curve);
        }

        private static void SetTangent(ConfigNode node, AnimationCurve curve, int index,
                                        bool isInTangent, float tangent)
        {
            if (index < 0 || index >= curve.length) return;
            var keyframe = curve[index];
            if (isInTangent) keyframe.inTangent = tangent;
            else keyframe.outTangent = tangent;
            curve.MoveKey(index, keyframe);
            WriteCurveToNode(node, curve);
        }

        private static void ComputeRanges(AnimationCurve curve, EditorState state)
        {
            if (curve.length == 0)
            {
                state.rangeMinTime = 0f; state.rangeMaxTime = 1f;
                state.rangeMinValue = 0f; state.rangeMaxValue = 1f;
                return;
            }

            float timeMin = curve[0].time;
            float timeMax = curve[curve.length - 1].time;
            float valueMin = float.MaxValue;
            float valueMax = float.MinValue;

            int sampleCount = Mathf.Max(curve.length * 20, 100);
            for (int i = 0; i <= sampleCount; i++)
            {
                float sampleTime = Mathf.Lerp(timeMin, timeMax, i / (float)sampleCount);
                float sampleValue = curve.Evaluate(sampleTime);
                valueMin = Mathf.Min(valueMin, sampleValue);
                valueMax = Mathf.Max(valueMax, sampleValue);
            }

            for (int i = 0; i < curve.length; i++)
            {
                valueMin = Mathf.Min(valueMin, curve[i].value);
                valueMax = Mathf.Max(valueMax, curve[i].value);
            }

            float timePadding = Mathf.Max((timeMax - timeMin) * 0.08f, 0.1f);
            float valuePadding = Mathf.Max((valueMax - valueMin) * 0.12f, 0.1f);

            state.rangeMinTime = timeMin - timePadding;
            state.rangeMaxTime = timeMax + timePadding;
            state.rangeMinValue = valueMin - valuePadding;
            state.rangeMaxValue = valueMax + valuePadding;
        }

        private static void DrawRect(Rect rect, Color color)
        {
            Color previousColor = GUI.color;
            GUI.color = color;
            GUI.DrawTexture(rect, WhiteTex);
            GUI.color = previousColor;
        }

        private static void DrawRectOutline(Rect rect, Color color)
        {
            DrawRect(new Rect(rect.x, rect.y, rect.width, 1), color);
            DrawRect(new Rect(rect.x, rect.yMax - 1, rect.width, 1), color);
            DrawRect(new Rect(rect.x, rect.y, 1, rect.height), color);
            DrawRect(new Rect(rect.xMax - 1, rect.y, 1, rect.height), color);
        }

        private static void DrawDisc(Vector2 center, float radius, Color color)
        {
            DrawRect(new Rect(center.x - radius, center.y - radius,
                              radius * 2, radius * 2), color);
        }

        private static void DrawLine(Vector2 from, Vector2 to, Color color)
        {
            float distance = Vector2.Distance(from, to);
            int stepCount = Mathf.Max(Mathf.CeilToInt(distance / 2f), 1);
            float thickness = 1f;
            Color previousColor = GUI.color;
            GUI.color = color;
            for (int i = 0; i <= stepCount; i++)
            {
                float fraction = i / (float)stepCount;
                Vector2 point = Vector2.Lerp(from, to, fraction);
                GUI.DrawTexture(new Rect(point.x - thickness * 0.5f, point.y - thickness * 0.5f,
                                         thickness, thickness), WhiteTex);
            }
            GUI.color = previousColor;
        }

        private static int ComputeHash(ConfigNode node)
        {
            unchecked
            {
                int hash = 17;
                foreach (string value in node.GetValuesStartsWith("key"))
                    hash = hash * 31 + value.GetHashCode();
                return hash;
            }
        }

        private static float NiceStep(float span, int targetLineCount)
        {
            float rawStep = span / targetLineCount;
            float magnitude = Mathf.Pow(10f, Mathf.Floor(Mathf.Log10(rawStep)));
            float normalized = rawStep / magnitude;

            float niceMultiplier;
            if (normalized < 1.5f) niceMultiplier = 1f;
            else if (normalized < 3.5f) niceMultiplier = 2f;
            else if (normalized < 7.5f) niceMultiplier = 5f;
            else niceMultiplier = 10f;

            return niceMultiplier * magnitude;
        }
    }
}
