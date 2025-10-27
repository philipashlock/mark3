// ProseMirror Bootstrap - Loads ES6 modules and exposes them as globals
console.log('📦 [Bootstrap] Starting ProseMirror library loading...');

// Track which modules we've loaded
let loadedCount = 0;
const expectedCount = 9;

async function loadProseMirror() {
    try {
        console.log('📦 [Bootstrap] Importing prosemirror-model...');
        const model = await import('./lib/prosemirror-model.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        console.log('📦 [Bootstrap] Importing prosemirror-state...');
        const state = await import('./lib/prosemirror-state.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        console.log('📦 [Bootstrap] Importing prosemirror-view...');
        const view = await import('./lib/prosemirror-view.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        console.log('📦 [Bootstrap] Importing prosemirror-transform...');
        const transform = await import('./lib/prosemirror-transform.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        console.log('📦 [Bootstrap] Importing prosemirror-commands...');
        const commands = await import('./lib/prosemirror-commands.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        console.log('📦 [Bootstrap] Importing prosemirror-schema-basic...');
        const schemaBasic = await import('./lib/prosemirror-schema-basic.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        console.log('📦 [Bootstrap] Importing prosemirror-schema-list...');
        const schemaList = await import('./lib/prosemirror-schema-list.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        console.log('📦 [Bootstrap] Importing prosemirror-history...');
        const history = await import('./lib/prosemirror-history.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        console.log('📦 [Bootstrap] Importing prosemirror-gapcursor...');
        const gapcursor = await import('./lib/prosemirror-gapcursor.js');
        loadedCount++;
        console.log(`📦 [Bootstrap] Loaded (${loadedCount}/${expectedCount})`);

        // Now expose the key classes as globals
        console.log('✅ [Bootstrap] All modules loaded, exposing as globals...');

        window.Schema = model.Schema;
        window.EditorState = state.EditorState;
        window.EditorView = view.EditorView;
        window.Slice = transform.Slice;
        window.ReplaceError = transform.ReplaceError;
        window.Step = transform.Step;
        window.StepResult = transform.StepResult;
        window.Transform = transform.Transform;
        window.baseKeymap = commands.baseKeymap;
        window.schemaBasic = schemaBasic.schema;
        window.gapCursor = gapcursor;

        console.log('✅ [Bootstrap] Globals exposed:');
        console.log('   window.Schema:', typeof window.Schema);
        console.log('   window.EditorState:', typeof window.EditorState);
        console.log('   window.EditorView:', typeof window.EditorView);

        // Signal that we're ready
        console.log('✅ [Bootstrap] Sending editorReady signal to Swift...');
        if (window.webkit?.messageHandlers?.editorBridge) {
            window.webkit.messageHandlers.editorBridge.postMessage({
                action: 'editorReady',
                message: 'ProseMirror bootstrap complete'
            });
            console.log('✅ [Bootstrap] editorReady message sent');
        } else {
            console.warn('⚠️ [Bootstrap] Swift bridge not available yet, will try again');
            // Try again in a moment
            setTimeout(() => {
                if (window.webkit?.messageHandlers?.editorBridge) {
                    window.webkit.messageHandlers.editorBridge.postMessage({
                        action: 'editorReady',
                        message: 'ProseMirror bootstrap complete (retry)'
                    });
                    console.log('✅ [Bootstrap] editorReady message sent (retry)');
                }
            }, 500);
        }

    } catch (error) {
        console.error('❌ [Bootstrap] Failed to load ProseMirror:', error);
        console.error('   Error message:', error.message);
        console.error('   Stack:', error.stack);
    }
}

// Start loading immediately
loadProseMirror();
