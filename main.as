CB::Sound@ totemSound = null;
B3D::Texture@ totemScreenTexture = null;

const float TOTEM_SPEED = 33.33;
const int TOTEM_FRAMES = 60;
const int PLAYER_IMMUNITY_TIME = 2.5 * 1000;
int totemStart = 0.0;
int totemFrame = 0;
int immunityTimer = -60000;
bool totemActivated = false;

float startedInjuries = 0.0;

float abs(float n)
{
    return n < 0 ? -n : n;
}

bool ActivateTotem()
{
    CB::Item@ totem = FindTotem();
    if (totem is null) return false;

    immunityTimer = PLAYER_IMMUNITY_TIME;
    totemStart = B3D::MilliSecs();
    totemActivated = true;
    totemSound.Play();

    startedInjuries = CB::Player::Injuries;

    totem.Remove(); // this means we can stack a lot of totems
    return true;
}

void Hook_PostLoad()
{
    @totemSound = CB::Sound::Load("SFX/totem.ogg");
    @totemScreenTexture = CB::LoadAnimTexture("GFX/totem.png", 3, 8, 8, 0, 60);
}

bool Hook_ExecuteConsoleCommand(string cmd)
{
    if (cmd == "qblds")
    {
        CB::Player::Bloodloss = 96;
        return true;
    }
    return false;
}

void Hook_Update()
{
    if (totemActivated)
    {
        if (totemSound is null)
            @totemSound = CB::Sound::Load("SFX/totem.ogg");
    
        if (totemScreenTexture is null)
            @totemScreenTexture = CB::LoadAnimTexture("GFX/totem.png", 3, 8, 8, 0, 60);

        totemFrame = (B3D::MilliSecs() - totemStart) / TOTEM_SPEED;
        totemScreenTexture.GetBuffer(totemFrame).Draw(int(B3D::GraphicsWidth * 0.25f), 0, int(B3D::GraphicsWidth * 0.5f), B3D::GraphicsHeight);

        if (totemFrame >= TOTEM_FRAMES - 1)
            totemActivated = false;
    }

    if (immunityTimer <= PLAYER_IMMUNITY_TIME && immunityTimer >= 0) // I LOVE STUPID TIMERS :DDDDDDD
    {
        immunityTimer -= B3D::MilliSecs() - totemStart;
        CB::Player::Injuries = B3D::Clamp(startedInjuries - (abs(immunityTimer - PLAYER_IMMUNITY_TIME) / PLAYER_IMMUNITY_TIME) * 4.0, 0.0, 5.0);
        CB::Player::CameraShakeTimer = 1.0;
    }
    if (immunityTimer <= 0 && !totemActivated && immunityTimer != -60000) // reset SCP's back to normal
    {
        CB::NPC::Current173.Idle = 0.0; // specially 173 
        immunityTimer = -60000;
    }
}

bool Hook_PostFillRoom(CB::Room r)
{
    if (r.Template.Name == "roompj")
    {
        CB::Item it = CB::Item::Create("totem", r.X + 800.0 / 256.0, r.Y + 176.0 / 256.0, r.Z + 1008.0 / 256.0);
        it.Collider.SetParent(r.Object);
    }    
    return true;
}

CB::Item@ FindTotem()
{
    CB::Item@ last = CB::Item::Last;
    for (CB::Item@ it = CB::Item::First; it !is null; @it = it.Next)
    {
        if (it.Picked && it.Template !is null && it.Template.Name == "totem")
            return it;
        if (it is last) break;   // never call .Next on the final node
    }
    return null;
}

bool Hook_MovePlayer() // deathtimer apparently is checked here
{
    if (CB::Player::DeathTimer > 0.0 || CB::Player::DeathTimer < 0.0 || CB::Player::Bloodloss >= 99.0)
    {
        if (FindTotem() !is null)
        {
            ActivateTotem();
            CB::Player::DeathTimer = 0.0;
            CB::Player::Bloodloss = 1.5;
            return true;
        }
    }
    return false;
}

bool Hook_KillPlayer()
{
    return ActivateTotem();
}
