import json
import os
import shutil
from uuid import uuid4
import typer
import moviepy.editor as mp
from slugify import slugify

app = typer.Typer(name="Dano Drevo Soundboard CLI")


@app.command("create")
def create_sound_from_video(
        title: str = typer.Option(..., prompt="Enter sound title"),
        video_file: str = typer.Option(..., prompt="Enter path to video file"),
        start_time: str = typer.Option("00:00", prompt="Enter clip start time"),
        duration: float = typer.Option(-1, prompt="Enter duration of the clip, in seconds", show_default=False),
        image: str = None
    ):
    with mp.VideoFileClip(video_file) as video:
        video.set_start(start_time)

        if duration > 0:
            video.set_duration(duration)

        audio_file = "content/static/sounds/" + slugify(f'{title}') + '.ogg'

        video.audio.write_audiofile(audio_file)

        add_sound(title, file=audio_file, image=image)



@app.command("add")
def add_sound(
        title: str = typer.Option(..., prompt="Enter sound title"), 
        file: str = typer.Option(..., prompt="Enter sound file"),
        sounds_file: str = "content/index.json",
        image: str = None
    ):
    typer.echo(f"Adding sound {title} to the list...")
    with open(sounds_file, "r", encoding='utf-8') as f: 
        sounds = json.load(f)

    sound = {
        "title": title,
        "id": str(uuid4()),
    }


    filename = slugify(title) + os.path.splitext(file)[1]
    try:
        shutil.copyfile(file, f"content/static/sounds/{filename}")
    except shutil.SameFileError:
        pass
    sound["sound"] = f"/static/sounds/{filename}"


    if image:
        typer.echo(f"Adding '{image}' as sound image")
        filename = slugify(title) + os.path.splitext(image)[1]
        try:
            shutil.copyfile(image, f"content/static/icons/{filename}")
        except shutil.SameFileError:
            pass
        sound["icon"] = f"/static/icons/{filename}"

    if sound["sound"] not in [s['sound'] for s in sounds]:
        sounds.append(sound)
        
    typer.echo(f"Adding sound: {sound}")

    with open(sounds_file, "w", encoding='utf-8') as f: 
        json.dump(sounds, f, indent=2)
        


if __name__ == "__main__":
    app()