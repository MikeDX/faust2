/* =============================================================================
 * faust2.PRG by Casper
 * (c) 2017 altsrc
 * ========================================================================== */

COMPILER_OPTIONS _case_sensitive;

program Faust2;
const
    // DIV command enums
    REGION_FULL_SCREEN = 0;
    SCROLL_FOREGROUND_HORIZONTAL = 1;
    SCROLL_FOREGROUND_VERTICAL   = 2;
    SCROLL_BACKGROUND_HORIZONTAL = 4;
    SCROLL_BACKGROUND_VERTICAL   = 8;
    FONT_ANCHOR_TOP_LEFT      = 0;
    FONT_ANCHOR_TOP_CENTER    = 1;
    FONT_ANCHOR_TOP_RIGHT     = 2;
    FONT_ANCHOR_CENTER_LEFT   = 3;
    FONT_ANCHOR_CENTERED      = 4;
    FONT_ANCHOR_CENTER_RIGHT  = 5;
    FONT_ANCHOR_BOTTOM_LEFT   = 6;
    FONT_ANCHOR_BOTTOM_CENTER = 7;
    FONT_ANCHOR_BOTTOM_RIGHT  = 8;

    // program enums
    MENU_OPTION_NONE = 0;
    MENU_OPTION_PLAY = 1;
    GAME_STATE_NOT_STARTED = 0;
    GAME_STATE_ACTIVE      = 1;
    GAME_STATE_GAME_OVER   = 2;

    // settings
    SCREEN_MODE = m640x400;
    SCREEN_WIDTH = 640;
    SCREEN_HEIGHT = 400;
    HALF_SCREEN_WIDTH = SCREEN_WIDTH / 2;
    HALF_SCREEN_HEIGHT = SCREEN_HEIGHT / 2;

    // file paths
    GFX_MAIN_PATH = "main.fpg";
    FNT_MENU_PATH = "16x16-w-arcade.fnt";
    FNT_GAME_PATH = "game.fnt";
global
    // resources
    __gfxMain;
    __fntSystem;
    __fntMenu;
    __fntGame;

    // game processes
    __playerController;

    // debug vars
    __logs[31];
    __logCount;
    __logsX = 100;
    __logsY = 10;
    __logsYOffset = 15;
begin
    // initialization
    set_mode(SCREEN_MODE);
    set_fps(60, 4);

    // load resources
    __gfxMain = load_fpg(GFX_MAIN_PATH);
    __fntSystem = 0;
    __fntMenu = load_fnt(FNT_MENU_PATH);
    //__fntGame = load_fnt(FNT_GAME_PATH); // TODO: find font

    // debugging
    LogValue("FPS", offset fps);

    // show title screen
    TitleScreen();
end



/* -----------------------------------------------------------------------------
 * Menu screens
 * ---------------------------------------------------------------------------*/

function TitleScreen()
private
    selected = MENU_OPTION_NONE;
    txtTitle;
begin
    // initialization
    clear_screen();
    put_screen(__gfxMain, __gfxMain + 1);
    txtTitle = write(
        __fntMenu, 
        HALF_SCREEN_WIDTH, 
        HALF_SCREEN_HEIGHT, 
        FONT_ANCHOR_CENTERED, 
        "PRESS ANY KEY TO PLAY");

    // wait for input
    repeat
        if (scan_code != 0)
            selected = MENU_OPTION_PLAY;
        end

        frame;
    until (selected != MENU_OPTION_NONE)

    // clean up
    delete_text(txtTitle);

    // handle selection
    if (selected == MENU_OPTION_PLAY)
        GameManager();
    end
end



/* -----------------------------------------------------------------------------
 * Gameplay
 * ---------------------------------------------------------------------------*/

function GameManager()
private
    state = GAME_STATE_NOT_STARTED;
    scrollBackground = 0;
begin
    // initialization
    clear_screen();

    // graphics
    start_scroll(
        scrollBackground, 
        __gfxMain, __gfxMain + 200, 0, 
        REGION_FULL_SCREEN, 
        SCROLL_FOREGROUND_HORIZONTAL + SCROLL_FOREGROUND_VERTICAL);

    // gameplay
    state = GAME_STATE_ACTIVE;
    __playerController = PlayerController(40, 40);

    // game loop
    repeat
        // TODO: gameplay goes here

        frame;
    until (state == GAME_STATE_GAME_OVER)
end



/* -----------------------------------------------------------------------------
 * Player
 * ---------------------------------------------------------------------------*/

process PlayerController(x, y)
private
    walkSpeed = 4;
    turnSpeed = 10000;

    velocityX;
    velocityY;

    mouseCursor;
    animator;
begin
    // initialization
    mouseCursor = MouseCursor();
    animator = CharacterAnimator();

    // debugging
    LogValue("angle", offset angle);
    //LogValue("targetAngle", offset targetAngle);
    //LogValue("angleDifference", offset angleDifference);
    loop
        // movement input
        if (key(_a))
            velocityX = -walkSpeed;
        else
            if (key(_d))
                velocityX = +walkSpeed;
            else
                velocityX = 0;
            end
        end

        if (key(_w))
            velocityY = -walkSpeed;
        else
            if (key(_s))
                velocityY = +walkSpeed;
            else
                velocityY = 0;
            end
        end

        // TODO: Refactor velocity out into separate process.
        // TODO: Normalize velocity vector.

        // apply velocity
        x += velocityX;
        y += velocityY;

        // look at the mouse cursor
        TurnTowards(angle, mouseCursor, turnSpeed);
        frame;
    end
end



/* -----------------------------------------------------------------------------
 * Character Animations
 * ---------------------------------------------------------------------------*/

process CharacterAnimator()
private
    arms;
    base;
    head;
begin
    // initialization
    arms = CharacterArms();
    base = CharacterBase();
    head = CharacterHead();

    loop
        x = father.x;
        y = father.y;
        angle = father.angle;
        frame;
    end
end

process CharacterArms()
begin
    // initialization
    graph = __gfxMain + 902;
    z = -90;
    loop
        x = father.x;
        y = father.y;
        angle = father.angle;
        frame;
    end
end

process CharacterBase()
begin
    // initialization
    graph = __gfxMain + 900;
    z = -100;
    loop
        x = father.x;
        y = father.y;
        angle = father.angle;
        frame;
    end
end

process CharacterHead()
begin
    // initialization
    graph = __gfxMain + 901;
    z = -110;
    loop
        x = father.x;
        y = father.y;
        angle = father.angle;
        frame;
    end
end



/* -----------------------------------------------------------------------------
 * User interface
 * ---------------------------------------------------------------------------*/

process MouseCursor()
begin
    // initialization
    graph = __gfxMain + 300;
    z = -1000;
    loop
        x = mouse.x;
        y = mouse.y;
        frame;
    end
end



/* -----------------------------------------------------------------------------
 * Utilities
 * ---------------------------------------------------------------------------*/

function TurnTowards(currentAngle, target, turnSpeed)
private
    currentAngleWrapped;
    targetAngle;
    targetAngleWrapped;
    greaterAngle;
    lesserAngle;
    counterClockwiseDifference;
    clockwiseDifference;
    angleDifference;
begin
    currentAngleWrapped = WrapAngle360(currentAngle);

    targetAngle = fget_angle(father.x, father.y, target.x, target.y);
    targetAngleWrapped = WrapAngle360(targetAngle);

    greaterAngle = Max(currentAngleWrapped, targetAngleWrapped);
    lesserAngle = Min(currentAngleWrapped, targetAngleWrapped);

    counterClockwiseDifference = WrapAngle360(greaterAngle - lesserAngle);
    clockwiseDifference = WrapAngle360(360000 - counterClockwiseDifference);

/*
    angleDifference = Min(counterClockwiseDifference, clockwiseDifference);

    if (counterClockwiseDifference < clockwiseDifference)
        if (angleDifference > turnSpeed)
            currentAngle += turnSpeed;
        else
            currentAngle = targetAngle;
        end
    else
        if (clockwiseDifference < counterClockwiseDifference)
            if (angleDifference > turnSpeed)
                currentAngle -= turnSpeed;
            else
                currentAngle = targetAngle;
            end
        end
    end
    */

    if (counterClockwiseDifference < clockwiseDifference)
        currentAngle += turnSpeed;
    else
        currentAngle -= turnSpeed;
    end

    LogValue("currentAngleWrapped", offset currentAngleWrapped);
    LogValue("targetAngle", offset targetAngle);
    LogValue("targetAngleWrapped", offset targetAngleWrapped);
    LogValue("greaterAngle", offset greaterAngle);
    LogValue("lesserAngle", offset lesserAngle);
    LogValue("counterClockwiseDifference", offset counterClockwiseDifference);
    LogValue("clockwiseDifference", offset clockwiseDifference);
    DeleteLastLog();
    DeleteLastLog();
    DeleteLastLog();
    DeleteLastLog();
    DeleteLastLog();
    DeleteLastLog();
    DeleteLastLog();

    //father.angle = currentAngle;
    father.angle = WrapAngle360(currentAngle);
end

function WrapAngle360(angle)
begin
    return ((angle + 360000) mod 360000);
end

function Min(a, b)
begin
    if (a > b)
        return (b);
    end

    return (a);
end

function Max(a, b)
begin
    if (a >= b)
        return (a);
    end

    return (b);
end



/* -----------------------------------------------------------------------------
 * Debugging
 * ---------------------------------------------------------------------------*/

process LogValue(string label, val)
private
    txtLogLabel;
    txtLogValue;
    logIndex;
begin
    logIndex = __logCount;
    __logs[__logCount] = id;
    __logCount++;

    x = __logsX;
    y = __logsY + (logIndex * __logsYOffset);

    label = label + ": ";

    txtLogLabel = write(
        __fntSystem,
        x,
        y,
        FONT_ANCHOR_TOP_RIGHT,
        label);

    txtLogValue = write_int(
        __fntSystem,
        x,
        y,
        FONT_ANCHOR_TOP_LEFT,
        val);
    loop
        frame;
    end
end

process DeleteLastLog()
begin
    signal(__logs[__logCount - 1], s_kill);
    __logCount--;
end



